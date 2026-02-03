# Lagoon Images Architecture

This document describes the architecture and workflows for building, testing, and maintaining the Lagoon base images repository. Lagoon provides optimized Docker images for Drupal, PHP, and related services, designed for Kubernetes environments.

---

## 1. Image Hierarchy & Dependency Structure

- **commons**: The foundational Alpine-based image, providing shared utilities (e.g., `/lagoon/`, `fix-permissions`, `tini`).
- **Base Images**: Direct descendants of `commons` (e.g., nginx, php-fpm, node, python, ruby, etc.).
- **Specialized Images**: Built on top of base images for specific use cases (e.g., `nginx-drupal`, `php-cli-drupal`, `varnish-drupal`).
- **Multi-Version Images**: Each service supports multiple versions (e.g., `php-8.3-fpm`, `node-22`, `varnish-8-persistent-drupal`).

**Naming Pattern:**
```
{service}-{version}[-variant][-specialization]
```
Examples: `php-8.3-fpm`, `node-22-builder`, `varnish-8-drupal`

**Dependency Management:**
- All images ultimately depend on `commons`.
- Dependencies are managed in `docker-bake.hcl` using the `contexts` parameter for each target.
- Specialized variants depend on their base image, and combined variants depend on the first specialization.

---

## 2. Build System

- **Orchestration:**
  - Centralized in `docker-bake.hcl` (all targets, dependencies, and groups defined here).
  - `Makefile` provides simple wrappers for common build commands.
- **Build Commands:**
  - `make build` — Build all images (respects dependency order).
  - `make build/{image}` — Build a specific image and its parents.
  - `make build-list` — List all buildable images.
  - `make clean && make build` — Force rebuild of all images.
  - Multi-platform builds (CI): use the background build + publish pattern (e.g., `make build-bg` followed by `make publish-testlagoon-images`), as used in the Jenkins pipeline.
- **Dockerfile Conventions:**
  - All Dockerfiles start with a standard block (ARGs, FROM, labels, ENV, and commons utilities copy).
  - Version-specific Dockerfiles are placed in `images/{service}/{version}.Dockerfile`.

---

## 3. Testing Framework

- **Test Structure:**
  - Tests are in `helpers/`:
    - `images-docker-compose.yml` + `TESTING_base_images_dockercompose.md` (base images)
    - `services-docker-compose.yml` + `TESTING_service_images_dockercompose.md` (service images)
- **Test Patterns:**
  - Each new image/variant must have a Docker Compose service definition and corresponding test commands.
  - Tests include version checks, extension/module checks, connectivity, and runtime validation.
  - PHP FPM images require startup wait checks; others (Node, Python, Ruby) do not.
- **Validation Workflow:**
  1. Build the image (`make build/{image}`)
  2. Set up test environment (copy/modify compose file, bring up services)
  3. Run every test command manually and verify output
  4. Check container status with `docker ps`
  5. Clean up test environment
- **CI Integration:**
  - Jenkins pulls the `lagoon-examples` repo and runs all tests after builds.
  - Tests are required to pass for all PRs and releases.

---

## 4. Version & Variant Management

- **Adding a New Version:**
  1. Add a new target in `docker-bake.hcl` (with correct contexts/dependencies)
  2. Add the target to the service-specific group and the `default` group
  3. Create the Dockerfile in the appropriate directory
  4. Add test coverage in helpers
  5. Validate all tests manually before commit
- **Variant Hierarchy:**
  - Follows a consistent pattern: base → specialization → combined specialization
  - Example: `varnish-8` → `varnish-8-drupal` → `varnish-8-persistent-drupal`

---

## 5. End-of-Life (EOL) & Deprecation

- **EOL Marking:**
  - When upstream support ends, add deprecation labels to the Dockerfile after OCI labels:
    - `LABEL sh.lagoon.image.deprecated.status="endoflife"`
    - `LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/{replacement}"`
  - Always suggest the latest stable, supported version as a replacement.
- **Full Removal:**
  - After a deprecation period, remove the Dockerfile, build system references, test infrastructure, and documentation.
  - Validate removal by ensuring no references remain and the build system works without the removed image.

---

## 6. Security & Scanning

- All images are scanned post-build using Trivy, Syft, and Grype.
- Results are output to `./scans/`.
- EOL/deprecated images are flagged for users and CI/CD systems.

---

## 7. Publishing & Release

- **Development:** Images published as `testlagoon/{image}:{branch}`
- **Main branch:** `testlagoon/{image}:latest` (multi-arch)
- **Tagged releases:** `uselagoon/{image}:latest` and `uselagoon/{image}:{version}`

---

## 8. Best Practices & Critical Reminders

- Always validate every test command against the actual built image before committing.
- Never assume test patterns or outputs—verify with real containers.
- Maintain strict dependency and naming conventions for all new images and variants.
- Mark EOL images promptly and provide clear upgrade paths.
- Keep documentation and test coverage up to date with all changes.

---

For detailed step-by-step instructions, see `.github/copilot-instructions.md`.
