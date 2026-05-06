# Lagoon Images – PR Review Rubric for AI Agents

## Before You Start (Required)

1. Identify affected image(s) by directory (`images/php-fpm/`, `images/nginx/`, etc.)
2. Classify the change type:
   - Base image change (`commons`, `nginx`, `php-fpm`)
   - Variant image change (`nginx-drupal`, `php-cli-drupal`)
   - Helper script change (`helpers/`)
   - Build system change (`docker-bake.hcl`, `Makefile`)
   - Documentation-only
3. If multiple image families are affected, note cross-image impact in the summary. Do **not** repeat the same comment across multiple files.

---

## 1. Base Image Version Pinning

**Checks:**
- [ ] `FROM` uses a fully-qualified tag (e.g. `alpine:3.19`, not `alpine:latest`)
- [ ] Major version bumps are intentional
- [ ] Digest pinning used for shared base images

**Comment templates:**

| Condition | Comment |
|-----------|---------|
| Unpinned tag | `Base image is not version-pinned. Pin to a specific version to ensure reproducible builds.` |
| Major version bump | `This bumps the base image major version. Confirm compatibility with downstream Lagoon services.` |

One comment per Dockerfile maximum. Digest pinning is encouraged for shared base images but not required elsewhere.

## 2. Layer construction and determinism

**Explicit checks**

Copilot must check:

RUN steps:

No interactive commands

No time-dependent behavior

Package installs:

Use --no-cache (apk)

Clean up package lists

No redundant layers adding then removing files

Comment rules

If temp artifacts remain:

“Temporary build artifacts are left in the final image. Clean up in the same layer to reduce image size.”

If layering is inefficient:

“Multiple RUN layers perform related setup. Consider consolidating to reduce image layers.”

No style commentary. Size and determinism only.

## 3. Helper scripts (helpers/, shared scripts)

**Explicit checks**

If a helper script changes, Copilot must verify:

It is used by multiple images

It remains POSIX-compatible

It fails fast (set -e or equivalent)

Error output is meaningful

Comment rules

If helper script behavior changes:

“This helper script is shared across multiple images. Confirm downstream impact and update relevant images if required.”

If error handling weakens:

“Helper scripts should fail fast with clear error output to avoid silent image misbuilds.”

Copilot must not suggest refactors unless behavior is broken.

## 4. Security posture (image-specific, not generic)

**Explicit checks**

Copilot must flag:

curl | sh without checksum verification

Downloaded binaries without integrity checks

Build tools present in final runtime images

Root user usage in runtime images (when avoidable)

Comment rules

External downloads:

“External download lacks integrity verification. Add checksum validation to reduce supply-chain risk.”

Runtime as root:

“Image runs as root. If intended for runtime use, consider a non-root user unless explicitly required.”

Copilot must not recommend security theatre. Only concrete risks.

## 5. Image intent and audience clarity

**Explicit checks**

The canonical "header" of a Lagoon Dockerfile is its OCI label block. Verify it includes:

- `org.opencontainers.image.source` — link to the file on GitHub
- `org.opencontainers.image.description` — one-line statement of purpose / audience (build vs runtime, what workload)
- `org.opencontainers.image.title` — `uselagoon/<image>` form
- `org.opencontainers.image.base.name` — what this image extends

Non-obvious `RUN` steps must carry an inline comment.

**Comment templates:**

| Condition | Comment |
|-----------|---------|
| Missing / vague description label | `OCI description label does not state image purpose or audience. Update to clarify intended use.` |
| Non-obvious build logic | `This step is non-obvious. Add a brief comment explaining why it is required.` |

One comment max per file.

## 6. Cross-Image Consistency

**Checks:**
- [ ] `ENV` variable naming follows established patterns
- [ ] All four `org.opencontainers.image.*` labels listed in §5 are present
- [ ] Directory structure aligns with similar images (`images/<family>/<version>.Dockerfile`)
- [ ] Common utilities copied from `commons` in the standard way (see [architecture.md §7.1](../../architecture.md#71-first-tier-images-from-upstream))
- [ ] **Target name uses dashes; published tag keeps dots** (e.g. `php-8-3-fpm` target → `php-8.3-fpm` tag)
- [ ] First-tier Dockerfiles use `ARG LOCAL_REPO` + `FROM ${LOCAL_REPO:-lagoon}/commons AS commons`; variants use `FROM ${LOCAL_REPO:-lagoon}/<parent>`

**Comment template:**

```
This image diverges from conventions used in similar Lagoon images. See architecture.md §7 for the expected pattern.
```

Reference existing repo patterns only. Do not invent new conventions.

## 7. Build wiring and test coverage

This is the highest-frequency source of CI failures in this repo. All four checks below must pass for any new image, version, or variant.

**Checks:**
- [ ] `docker-bake.hcl` has a `target` block for the image
- [ ] The target name is added to its **service-specific group** (e.g. `group "php"`)
- [ ] The target name is also added to **`group "default"`**
- [ ] The target's `contexts` map is correct:
  - First-tier image → references `${LOCAL_REPO}/commons: target:commons`
  - Variant / specialization → references its **direct parent only**, not commons
  - Exception: a Dockerfile that declares its own `FROM ${LOCAL_REPO}/commons AS commons` build stage must also list commons in `contexts` (see [architecture.md §7.3](../../architecture.md#73-the-commons-as-build-stage-exception))
- [ ] Combined specializations layer on the **first** specialization, not on a sibling variant (e.g. `varnish-8-persistent-drupal` extends `varnish-8-drupal`, not `varnish-8-persistent`)
- [ ] New image has a service block in `helpers/images-docker-compose.yml` or `helpers/services-docker-compose.yml`
- [ ] New image has matching test commands in the corresponding `helpers/TESTING_*_dockercompose.md`

**Comment templates:**

| Condition | Comment |
|-----------|---------|
| Target missing from `default` or service group | `Target is defined but not added to group "default" (and/or its service group). CI will silently skip it.` |
| Variant lists commons in `contexts` | `Variant images should reference only their direct parent in \`contexts\`. Remove the commons entry unless this Dockerfile has an explicit \`FROM commons AS commons\` stage.` |
| First-tier image missing commons context | `First-tier image is missing \`${LOCAL_REPO}/commons: target:commons\` in its bake \`contexts\`.` |
| No test coverage | `New image has no compose entry or TESTING_*.md commands. Add coverage in helpers/.` |

Do not speculate about test frameworks or suggest new testing approaches.

## 8. Documentation

**Checks:**
- [ ] [README.md](../../README.md) updated when image behaviour, supported tags, or consumer-facing variants change
- [ ] [.github/copilot-instructions.md](../../.github/copilot-instructions.md) updated when a recipe / workflow changes (e.g. new gotcha, new test pattern)
- [ ] [architecture.md](../../architecture.md) updated when something *structural* changes (new image tier, new build variable, new pipeline stage, new convention)

**Comment template:**

```
Documentation does not reflect this change. Update README / copilot-instructions / architecture as appropriate.
```

## 9. Lifecycle and backward compatibility

The image lifecycle is: **active → EOL-labelled → removed (after ≥ 6 months)**. See [architecture.md §10](../../architecture.md#10-image-lifecycle).

**Checks:**
- [ ] No image removed without prior EOL labelling and a deprecation window
- [ ] No published tag removed without an EOL marker on the image first
- [ ] No default behaviour or `ENV` changed without a note in the PR description
- [ ] No changes that break existing consumers without a clear upgrade path

**Comment template:**

```
This change alters existing image behaviour. Confirm backward compatibility or document the breaking change and upgrade path.
```

Do not block internal refactors that do not affect external behaviour.

## 10. End-of-life labelling

Applies to PRs that mark an image as EOL or update an existing EOL marker. The full procedure is [Recipe 5 in copilot-instructions](../../.github/copilot-instructions.md#recipe-5--mark-an-image-as-end-of-life).

**Checks:**
- [ ] Both labels present, in the standard form:
  ```dockerfile
  LABEL sh.lagoon.image.deprecated.status="endoflife"
  LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/<replacement>"
  ```
- [ ] The suggested replacement **already exists in this repo** as a built image
- [ ] The replacement is the latest stable / longest-supported equivalent (not an arbitrary newer version)
- [ ] The image continues to build and publish — only the labels are added, nothing is removed yet

**Comment templates:**

| Condition | Comment |
|-----------|---------|
| Suggested replacement missing or not built here | `Suggested replacement image is not built by this repo. Point to an image that exists in docker-bake.hcl.` |
| Image gutted instead of labelled | `EOL marking should only add the two deprecation labels. Image must keep building and publishing for the deprecation window.` |

---

## Review Output Format

Every review **must** use this exact structure:

```markdown
## Summary
- **Images affected:** [list affected image directories]
- **Risk level:** low | medium | high
- **Backward compatible:** yes | no | n/a

## Blocking Issues
[Issues that break builds, introduce security risks, or break backward compatibility.]
[If none: "No blocking issues."]

## Non-Blocking Suggestions
[Grouped, concise suggestions. Omit section if none.]
```

**Rules:**
- No praise or positive commentary
- No filler text or restatement of the diff
- No repeating the same comment across multiple files
