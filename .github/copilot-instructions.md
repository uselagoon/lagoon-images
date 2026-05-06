# Lagoon Base Images — AI Agent Instructions

> **Architecture, naming, dependency model, build system, CI flow:**
> see [architecture.md](../architecture.md). This file is intentionally
> task-focused — it tells you **what to do**, not **why the repo is
> shaped the way it is**.

---

## When reviewing a PR

### Instruction source for CI Copilot reviews

For guidance that must be enforced on every automated PR review, place it in
`.github/instructions/*.instructions.md`.

Keep this file as task-focused guidance and workflow recipes. Linked docs
such as `architecture.md` and `docs/reviewing/PR_REVIEW_RUBRIC.md` are
reference material. Use `.github/instructions/pr-review.instructions.md` as
the canonical machine-consumed PR review policy.

Use [`.github/instructions/pr-review.instructions.md`](instructions/pr-review.instructions.md)
for enforceable review checks, and
[docs/reviewing/PR_REVIEW_RUBRIC.md](../docs/reviewing/PR_REVIEW_RUBRIC.md)
for explanatory context.
Focus on:

1. **Correctness** — reproducible builds, explicit version pins.
2. **Security** — no unverified external downloads, minimal attack surface.
3. **Testing** — every new image / variant has compose + TESTING markdown coverage.
4. **Clarity** — labels, comments, intent.
5. **Performance** — minimal final image size.
6. **Consistency** — naming, Dockerfile conventions, group/target wiring match the rest of the repo.
7. **Backward compatibility** — no silent breaking changes.
8. **Maintenance** — upstream version is current; deprecation labels present where applicable.

Group findings by category. Skip nits already covered by linters.

---

## Recipe 1 — Add a new version of an existing service

Example: adding `python-3.15`.

### 1. Create the Dockerfile

`images/python/3.15.Dockerfile`, following the **first-tier pattern**
documented in [architecture.md §7.1](../architecture.md#71-first-tier-images-from-upstream).

### 2. Update `docker-bake.hcl` — three edits, all required

```hcl
# (a) New target
target "python-3-15" {
  inherits   = ["default"]
  context    = "images/python"
  dockerfile = "3.15.Dockerfile"
  tags       = tags("python-3.15")
  contexts   = {
    "${LOCAL_REPO}/commons": "target:commons"
  }
}

# (b) Add to the service-specific group
group "python" {
  targets = [
    "commons",
    # … existing versions …
    "python-3-15",
  ]
}

# (c) Add to the default group
group "default" {
  targets = [
    # … existing targets …
    "python-3-15",
    # … more targets …
  ]
}
```

> **Forgetting (b) or (c) means the image silently won't be built by CI.**

Target names use dashes (`python-3-15`). Tags keep dots (`python-3.15`).

### 3. Add test coverage

- For a runtime/HTTP service: add a service block to
  [helpers/images-docker-compose.yml](../helpers/images-docker-compose.yml)
  and test commands to
  [helpers/TESTING_base_images_dockercompose.md](../helpers/TESTING_base_images_dockercompose.md).
- For a stateful service: same pattern in
  [helpers/services-docker-compose.yml](../helpers/services-docker-compose.yml)
  and [helpers/TESTING_service_images_dockercompose.md](../helpers/TESTING_service_images_dockercompose.md).

### 4. Validate locally — non-negotiable

```bash
make build/python-3.15

cp helpers/images-docker-compose.yml docker-compose.yml
sed -i '' 's/uselagoon/lagoon/g' docker-compose.yml   # macOS sed
docker compose up -d python-3-15 commons

# Run EVERY new TESTING_*.md command for this image and confirm output
docker compose exec -T python-3-15 sh -c "python --version" | grep "3.15"
# … etc …

docker ps --filter label=com.docker.compose.project=lagoon-images | grep Up | grep python-3-15

docker compose down && rm docker-compose.yml
```

**Never copy version strings or grep patterns from another service
without verifying against the actually-built image** — Redis, MariaDB
and PHP have all caused CI failures this way.

---

## Recipe 2 — Add a new variant of an existing service

Example: adding `service-X-persistent-drupal` for a service that already
has `service-X` and `service-X-drupal`.

### 1. Create the Dockerfile

`images/service-persistent-drupal/X.Dockerfile`, using the **variant
pattern** from [architecture.md §7.2](../architecture.md#72-variants--specializations-from-a-lagoon-parent).
A combined specialization (`-persistent-drupal`) layers on the *first*
specialization (`-drupal`), not on `-persistent`.

### 2. Wire it in `docker-bake.hcl`

```hcl
target "service-X-persistent-drupal" {
  inherits   = ["default"]
  context    = "images/service-persistent-drupal"
  dockerfile = "X.Dockerfile"
  tags       = tags("service-X-persistent-drupal")
  contexts   = {
    "${LOCAL_REPO}/service-drupal": "target:service-X-drupal"
  }
}
```

Variant targets **only reference their direct parent**, not commons.
**Exception:** if the Dockerfile has its own `FROM ${LOCAL_REPO}/commons AS commons`
build stage (e.g. `solr-9-drupal` does this to use git/curl from
commons), it must also list commons in `contexts`. See
[architecture.md §7.3](../architecture.md#73-the-commons-as-build-stage-exception).

Then add the target to the service group **and** the `default` group.

### 3. Test + validate as in Recipe 1, step 4.

For variants, the normal expectation is **targeted validation** rather
than re-running the full base-image test suite: startup check, version
check, and assertions specific to the variant behavior (for example
Drupal VCL or persistent cache settings).

---

## Recipe 3 — Add a brand-new service with multiple variants

Order of operations:

1. Create all Dockerfiles in dependency order:
   `service-X` → `service-X-drupal` → `service-X-persistent` → `service-X-persistent-drupal`.
2. Add **all** targets to `docker-bake.hcl`. The base targets commons,
   variants reference their parent. Add every target to a new (or
   existing) service group **and** to `default`.
3. Add compose entries + TESTING commands for every variant.
4. `make build/service-X-persistent-drupal` (which transitively builds the rest).
5. Fully validate the **base** image via the local compose loop in
  Recipe 1 step 4, then run targeted smoke checks for each variant.
6. Commit Dockerfiles + bake changes + helpers in a single PR.

---

## Recipe 4 — Test patterns by service type

These are *patterns*. Always run them against the built image and adjust
to real output before committing.

Default testing depth:

- Run the full verification set on the base image for the service.
- For variants, run focused checks that prove the variant delta
  (plus startup and version checks).
- Only run full suites on every variant when the change is broad enough
  to affect all variants.

**PHP (FPM on port 9000)** — needs a startup wait:
```bash
docker run --rm --net all-images_default jwilder/dockerize \
  dockerize -wait tcp://php-X-Y-dev:9000 -timeout 1m
docker compose exec -T php-X-Y-dev sh -c "php -v" | grep "X.Y"
docker compose exec -T php-X-Y-dev sh -c "php -m" | grep "<extension>"
```

**Python / Node / Ruby (HTTP on port 3000)** — no wait needed:
```bash
docker compose exec -T <svc>-X-Y sh -c "<runtime> --version" | grep "X.Y"
docker compose exec -T commons sh -c "curl <svc>-X-Y:3000/<endpoint>" | grep "<expected>"
```

**Databases (mariadb / mysql / postgres / mongo)**:
```bash
docker compose exec -T <svc>-X-Y sh -c "<client> --version" | grep "X.Y"
docker compose exec -T <svc>-X-Y sh -c "<server-version-cmd>" | grep "X.Y"
docker compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/SERVICE?service=<svc>-X-Y" | grep "SERVICE_HOST="
```

**Varnish**:
```bash
docker compose exec -T commons sh -c "curl -I varnish-X:8080" | grep -i "Varnish" | grep -i "X."
docker compose exec -T varnish-X sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_bodyaccess.so
docker compose exec -T varnish-X sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_dynamic.so
```

**PHP dev vs prod environments** — keep separate compose entries:
```yaml
php-X-Y-dev:
  environment:
    - LAGOON_ENVIRONMENT_TYPE=development
    - XDEBUG_ENABLE=true

php-X-Y-prod:
  environment:
    - LAGOON_ENVIRONMENT_TYPE=production
```

Every new service should also have a `docker ps` startup check:
```bash
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep <svc>-X-Y
```

---

## Recipe 5 — Mark an image as End-of-Life

After the standard OCI labels in the Dockerfile, add:

```dockerfile
LABEL sh.lagoon.image.deprecated.status="endoflife"
LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/<replacement>"
```

**Replacement selection** (in priority order): longest remaining
upstream support → latest LTS / stable → reasonable upgrade path. The
replacement must already exist in this repo. Examples:

| EOL image      | Suggested replacement |
| -------------- | --------------------- |
| `mariadb-10.6` | `mariadb-11.4`        |
| `postgres-14`  | `postgres-17`         |
| `php-8.2`      | `php-8.5`             |
| `python-3.10`  | `python-3.14`         |

Keep the image building and publishing — only add the labels. Trivy /
Syft / Grype and the Lagoon platform consume them to warn users.

---

## Recipe 6 — Remove an EOL image (after ≥ 6 months)

1. `rm images/<service>/<version>.Dockerfile`
2. In `docker-bake.hcl`: delete the `target` block, remove the target
   name from the service group, **and** remove it from the `default`
   group.
3. Remove the service entry from
   [helpers/images-docker-compose.yml](../helpers/images-docker-compose.yml)
   or [helpers/services-docker-compose.yml](../helpers/services-docker-compose.yml).
4. Remove all related commands from the relevant
   `helpers/TESTING_*_dockercompose.md`.
5. Verify the cleanup:
   ```bash
   grep -r "<service>-<version>" . --exclude-dir=.git --exclude-dir=scans
   make build-list | grep "<service>-<version>"   # should be empty
   ```

---

## Critical gotchas

- **Three bake edits, not one.** Adding a target without also adding it
  to its service group **and** `default` means CI silently won't build
  it. This is the most common mistake.
- **Variants do not list commons in `contexts`.** Only first-tier
  images do — unless the Dockerfile has an explicit
  `FROM ${LOCAL_REPO}/commons AS commons` build stage.
- **Combined specializations layer on the first specialization.**
  `varnish-8-persistent-drupal` extends `varnish-8-drupal`, not
  `varnish-8-persistent`.
- **Target names use dashes; tags keep dots.** `php-8-3-fpm` (target)
  vs `php-8.3-fpm` (tag).
- **Always run every TESTING command against the actual built image
  before committing.** Do not assume version strings — verify them
  (e.g. `redis_version:7.2.6` vs `7.2.4` has caused CI failures).
- **Local compose testing requires `sed 's/uselagoon/lagoon/g'`** so the
  compose file resolves to your locally-built tags, not the published
  ones.
