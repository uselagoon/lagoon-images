# Lagoon Base Images - AI Agent Instructions

This repository builds Docker base images for Lagoon - a Drupal & PHP hosting platform optimized for Kubernetes.

# Review instructions for AI Agents

Follow the PR Review Rubric defined in docs/reviewing/PR_REVIEW_RUBRIC.md.
Review PRs with focus on:
1. Functional correctness: reproducible builds, explicit version pins.
2. Security: no unverified external downloads, minimal attack surface.
3. Testing: CI coverage and smoke tests exist.
4. Clarity: documented intent and comments.
5. Performance: minimal final image size.
6. Consistency: shared conventions align with other images.
7. Documentation: readme explains build & usage.
8. Backward compatibility: no silent breaking changes.
9. Maintenance: up-to-date with upstream.

Summarize issues by category, avoid low-signal style comments already covered by linters.



## Architecture Overview

### Image Hierarchy & Dependencies
- **commons**: Foundation Alpine-based image with shared utilities (`/lagoon/`, `fix-permissions`, `tini`, etc.)
- **Base images**: Direct children of commons (nginx, php-fpm, node, python, etc.)  
- **Specialized images**: Built on base images (nginx-drupal, php-cli-drupal, varnish-drupal)
- **Multi-version images**: Multiple versions per service (php-8.1-fpm, php-8.2-fpm, node-20, node-22, etc.)

Image names follow pattern: `{service}-{version}[-variant][-specialization]`
Examples: `php-8.3-fpm`, `node-22-builder`, `varnish-6-drupal`, `varnish-8-persistent-drupal`

### Critical Build Dependencies (docker-bake.hcl)
Image dependencies are managed through the `contexts` parameter in each target:
```hcl
target "nginx-drupal" {
  contexts = {
    "${LOCAL_REPO}/nginx": "target:nginx"
  }
}

target "php-8-3-cli" {
  contexts = {
    "${LOCAL_REPO}/php-8.3-fpm": "target:php-8-3-fpm"
  }
}
```

All images depend on `commons` as the foundation, specified in their contexts.

## Essential Development Workflows

### Building Images
```bash
# Build everything (respects dependencies)
make build

# Build specific image and its parents
make build/php-8.3-fpm

# List all buildable images  
make build-list

# Force rebuild (removes build markers)
make clean && make build

# Multi-platform builds (CI only, see Jenkins pipeline)
# Use background build + publish pattern as used in Jenkins:
make build-bg PUBLISH_PLATFORM_ARCH='linux/amd64,linux/arm64/v8'
make publish-testlagoon-images PUBLISH_PLATFORM_ARCH='linux/amd64,linux/arm64/v8'
```

### Testing Images
Jenkins pulls `lagoon-examples` repository and runs comprehensive tests:
- Base image functionality tests (`helpers/TESTING_base_images_dockercompose.md`)  
- Service integration tests (`helpers/TESTING_service_images_dockercompose.md`)
- Drupal-specific workload tests

Test files demonstrate expected configurations and validate:
- PHP extensions (xdebug, newrelic, blackfire)
- Environment-specific configs (dev vs prod)
- Service connectivity and version verification

### Publishing Strategy
- **Development**: `testlagoon/{image}:{branch}` for all branches/PRs
- **Main branch**: `testlagoon/{image}:latest` + multi-arch builds
- **Tagged releases**: `uselagoon/{image}:latest` and `uselagoon/{image}:{version}`

## Project-Specific Patterns

### Service Variant Hierarchy
Many services follow a consistent variant pattern for specialized use cases:

**Base Service** → **Specialized Variants**
- `varnish-8` → `varnish-8-drupal`, `varnish-8-persistent`
- `varnish-8-drupal` → `varnish-8-persistent-drupal` (combines both specializations)
- `php-8.3-fpm` → `php-8.3-cli` → `php-8.3-cli-drupal`

**Common Variant Types:**
- **`-drupal`**: Drupal-specific configuration (VCL files, modules, settings)
- **`-persistent`**: Persistent storage configuration (volumes, file-based caching)
- **`-builder`**: Development/build-time tooling (additional packages, dev dependencies)
- **`-cli`**: Command-line variants with additional tools

**Variant Dependency Pattern (docker-bake.hcl):**
```hcl
# Base service depends on commons
target "service-X" {
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
  }
}

# Specialized variants depend on base service
target "service-X-drupal" {
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
    "${LOCAL_REPO}/service": "target:service-X"
  }
}

# Combined variants depend on first specialization
target "service-X-persistent-drupal" {
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
    "${LOCAL_REPO}/service-drupal": "target:service-X-drupal"
  }
}
```

### Dockerfile Conventions
All Dockerfiles start with:
```dockerfile
ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS commons
FROM upstream:version

# Standard labels
ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
# ... more labels

ENV LAGOON={service-name}

# Copy commons utilities
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/
```

### Docker Bake Target Naming
Each image version has an explicit target definition in docker-bake.hcl:
```hcl
target "php-8-3-fpm" {              # Target name (dashes replace dots)
  context = "images/php-fpm"        # Image folder
  dockerfile = "8.3.Dockerfile"     # Version-specific Dockerfile
  tags = tags("php-8.3-fpm")        # Published image name
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"      # Parent dependencies
  }
}
```

Note: Target names use dashes instead of dots (e.g., `php-8-3-fpm` vs `php-8.3-fpm` in tags).

### Environment Variables & Configuration
- `LAGOON_VERSION`: Git tag or "development"  
- `CI_BUILD_TAG`: Unique identifier for CI builds
- `LOCAL_REPO`: Base repository for parent images (lagoon/testlagoon/uselagoon)
- Development images enable xdebug, have higher memory limits
- Production images disable debug features, enforce stricter security

### Security & Vulnerability Scanning
Post-build scanning with Trivy, Syft, and Grype:
```bash
make scan-images  # Outputs to ./scans/*.{trivy,syft,grype}.txt
```

## Key Files & Integration Points

### Critical Build Files
- `docker-bake.hcl`: Central build orchestration with all image targets and dependencies
- `Makefile`: Simple wrapper that invokes docker buildx bake commands
- `Jenkinsfile`: Multi-stage CI pipeline with parallel builds and testing
- `build.txt`: Cross-reference table of built images with timestamps
- `helpers/images-docker-compose.yml`: Test service definitions

### Commons Foundation  
- `/lagoon/entrypoints/`: Initialization scripts run on container start
- `/lagoon/entrypoints.sh`: Sources all entrypoint files alphabetically 
- `/bin/fix-permissions`: Utility for container permission management
- `/bin/ep`: envplate binary for environment variable templating

### Version Management
New service versions require updates to:
1. New target definition in `docker-bake.hcl` following naming conventions
2. Add target to service-specific group in `docker-bake.hcl` (e.g., `python`, `node`, `ruby`)
3. Add target to the `default` group in `docker-bake.hcl`
4. New Dockerfile in appropriate subdirectory
5. Test coverage in helper files

**Critical docker-bake.hcl Pattern**: Each version gets an explicit target:
```hcl
# Add new target for the version
target "python-3-15" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
  }
  dockerfile = "3.15.Dockerfile"
  tags = tags("python-3.15")
}

# Add to the service-specific group
group "python" {
  targets = [
    "python-3-10",
    "python-3-11",
    "python-3-12",
    "python-3-13",
    "python-3-14",
    "python-3-15"  # New version added here
  ]
}

# Add to the default group
group "default" {
  targets = [
    "commons",
    # ... existing targets ...
    "python-3-10",
    "python-3-11",
    "python-3-12",
    "python-3-13",
    "python-3-14",
    "python-3-15",  # New version added here too
    # ... more targets ...
  ]
}
```

**CRITICAL: When adding new service versions, you must make THREE docker-bake.hcl changes:**
1. Add complete target definition with contexts specifying dependencies
2. Add target name to the appropriate service-specific group (e.g., `python`, `node`, `ruby`)
3. Add target name to the `default` group

When adding new images, follow the established naming and dependency patterns. The docker-bake.hcl file explicitly defines all targets and their dependencies through the `contexts` parameter.

## Testing Framework & Adding New Tests

### Test File Structure
Tests are organized in `helpers/` directory with two main categories:

- **Base Images**: `images-docker-compose.yml` + `TESTING_base_images_dockercompose.md`
  - Tests foundational images (commons, php-fpm, node, python, ruby)
  - Focuses on runtime behavior, extensions, configurations

- **Service Images**: `services-docker-compose.yml` + `TESTING_service_images_dockercompose.md` 
  - Tests database and infrastructure services (postgres, mariadb, redis, etc.)
  - Focuses on service connectivity, version verification, data operations

### Adding Tests for New Images

#### 1. Add Docker Compose Service Definition
**For Base Images** (`helpers/images-docker-compose.yml`):
```yaml
new-service-X-Y:
  image: uselagoon/new-service-X.Y:latest
  ports:
    - "PORT"
  << : *default-user
  environment:
    - SERVICE_SPECIFIC_ENV=value
  command: ["sh", "-c", "setup && exec service-daemon"]
```

**For Service Images** (`helpers/services-docker-compose.yml`):
```yaml
new-service-X-Y:
  image: uselagoon/new-service-X.Y:latest
  ports:
    - "SERVICE_PORT"
  << : *default-user
  environment:
    - CONFIGURATION_VAR=value
```

#### 2. Add Startup Wait Checks (Service-Specific)
Add dockerize wait commands in test markdown files **only for services that require it**:

**PHP Services** (FPM on port 9000):
```bash
docker run --rm --net all-images_default jwilder/dockerize \
  dockerize -wait tcp://php-X-Y-dev:9000 -timeout 1m
```

**Note**: Python, Node, Ruby, and other HTTP server services on port 3000 do NOT need dockerize wait commands as they start up quickly and are tested directly via HTTP requests.

#### 3. Create Version & Functionality Tests
Follow established patterns for each service type:

**Database Services Pattern**:
```bash
# Version verification (client & server)
docker compose exec -T new-service-X-Y sh -c "client-cmd --version" | grep "X.Y"
docker compose exec -T new-service-X-Y sh -c "server-version-cmd" | grep "X.Y"

# Connectivity & credentials
docker compose exec -T new-service-X-Y sh -c "connect-test" | grep "expected-output"

# Data operations via internal test service
docker compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/SERVICE?service=new-service-X-Y" | grep "SERVICE_HOST="
```

**Runtime Services Pattern (Python/Node/Ruby)**:
```bash
# Version check
docker compose exec -T service-X-Y sh -c "runtime --version" | grep "X.Y"

# Service functionality via HTTP endpoint (port 3000)
docker compose exec -T commons sh -c "curl service-X-Y:3000/endpoint" | grep "expected-response"

# Basic tools verification
docker compose exec -T service-X-Y sh -c "package-manager list" | grep "expected-package"
```

**PHP Services Pattern**:
```bash
# Version check
docker compose exec -T php-X-Y-dev sh -c "php -v" | grep "X.Y"

# Extensions verification
docker compose exec -T php-X-Y-dev sh -c "php -m" | grep "expected-extension"
```

#### 4. Environment-Specific Testing
**Development vs Production environments** (PHP pattern):
```yaml
# Dev environment with debug extensions
new-service-dev:
  environment:
    - LAGOON_ENVIRONMENT_TYPE=development  
    - XDEBUG_ENABLE=true
    - DEBUG_EXTENSION=true

# Production environment with security hardening  
new-service-prod:
  environment:
    - LAGOON_ENVIRONMENT_TYPE=production
    - SECURITY_SETTING=strict
```

#### 5. Service List Verification
Add `docker ps` checks to verify container startup:
```bash
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep new-service-X-Y
```

#### 6. **CRITICAL: Test Validation - MANDATORY**
**Every single test command MUST be run and validated before committing changes. This is not optional.**

**Step-by-step validation workflow:**

1. **Build the image first:**
```bash
make build/new-service-X-Y  # Must succeed without errors
```

2. **Set up test environment:**
```bash
# Copy and modify for local testing
cp helpers/images-docker-compose.yml docker-compose.yml
sed -i 's/uselagoon/lagoon/g' docker-compose.yml
docker compose up -d new-service-X-Y commons
```

3. **Run EVERY test command individually:**
```bash
# Test each command from TESTING_*_dockercompose.md one by one
docker compose exec -T new-service-X-Y version-cmd | grep expected-pattern
docker compose exec -T commons sh -c "curl new-service-X-Y:3000/endpoint" | grep expected
# ... test ALL commands you added
```

4. **Verify docker ps checks:**
```bash
docker ps --filter label=com.docker.compose.project=lagoon-images | grep Up | grep new-service-X-Y
```

5. **Clean up:**
```bash
docker compose down && rm docker-compose.yml
```

**NEVER assume test commands work - always verify against the actual built image:**
- Test individual commands against the built image first
- Check actual command output before writing grep patterns  
- Verify version patterns match real output, not assumptions
- Don't copy test patterns from other services without validation

**Common validation mistakes that cause CI failures:**
- Assuming version numbers without checking actual output
- Using hardcoded compatibility versions (e.g., redis_version:7.2.6 vs 7.2.4)
- Not testing grep patterns against real command output
- Copying version numbers from other similar services without verification
- Skipping the validation step entirely

### Service-Specific Testing Patterns

**Varnish Services Pattern:**
```bash
# Version verification via HTTP headers
docker compose exec -T commons sh -c "curl -I varnish-X:8080" | grep -i "Varnish" | grep -i "X."

# Vmod availability checks
docker compose exec -T varnish-X sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_bodyaccess.so
docker compose exec -T varnish-X sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_dynamic.so

# Functionality verification
docker compose exec -T varnish-X sh -c "timeout 3s varnishlog -d || true" | grep User-Agent | head -1
```

**Database Services Pattern:**
```bash
# Version verification (client & server)
docker compose exec -T service-X-Y sh -c "client-cmd --version" | grep "X.Y"
docker compose exec -T service-X-Y sh -c "server-version-cmd" | grep "X.Y"

# Connectivity & operations
docker compose exec -T service-X-Y sh -c "connect-test" | grep "expected-output"
```

### Testing Commands Summary
```bash
# Run base image tests
TEST=./all-images/TESTING_base_images* yarn test

# Run service image tests  
TEST=./all-images/TESTING_service_images* yarn test

# Local development testing
cp helpers/images-docker-compose.yml docker-compose.yml
docker compose up -d
# Run individual test commands from markdown files
```

### Integration with CI Pipeline
Tests run automatically in Jenkins via `lagoon-examples` repository:
1. Jenkins clones examples and replaces image references
2. Runs both base and service image test suites
3. Validates against both simple and advanced Drupal workloads
4. Tests are executed after successful multi-platform image builds

## Post-Implementation Validation Checklist

When adding a new image version, **always complete this validation workflow:**

### 1. Build Verification
```bash
make build/new-service-X-Y  # Must complete without errors
make build-list | grep new-service-X-Y  # Appears in build list
grep new-service-X-Y build.txt  # Tracked in build log
```

### 2. Image Functionality Testing
```bash
# Basic functionality
docker run --rm lagoon/new-service-X-Y service-cmd --version

# Service-specific validation
docker run --rm -d --name test-svc lagoon/new-service-X-Y
docker exec test-svc basic-connectivity-test
docker rm -f test-svc
```

### 3. Test Command Validation - REQUIRED BEFORE COMMIT
**MANDATORY: Run every single test command manually before committing any changes:**
```bash
# Replace uselagoon with lagoon for local testing
sed 's/uselagoon/lagoon/g' helpers/services-docker-compose.yml > temp-compose.yml
docker compose -f temp-compose.yml up -d new-service-X-Y commons

# Test EVERY SINGLE command from TESTING_*_dockercompose.md individually
docker compose -f temp-compose.yml exec -T new-service-X-Y version-cmd | grep expected-pattern
docker compose -f temp-compose.yml exec -T commons sh -c "curl ..." | grep expected
# Continue for ALL test commands you added...

# Verify docker ps checks work
docker ps --filter label=com.docker.compose.project=temp-compose | grep Up | grep new-service-X-Y

# Clean up
docker compose -f temp-compose.yml down && rm temp-compose.yml
```

**🚨 CRITICAL: If ANY test command fails, fix it before committing. Untested changes will break CI.**

### 4. Integration Testing
Run the complete test suite locally to ensure no regressions:
```bash
# Copy and modify for local testing
cp helpers/services-docker-compose.yml docker-compose.yml
sed -i 's/uselagoon/lagoon/g' docker-compose.yml
docker compose up -d
# Manually run test commands from markdown files
docker compose down
```

**Never assume test commands work - always verify against the actual built image before committing changes.**

## 🚨 MANDATORY TEST VALIDATION REMINDER

**BEFORE COMMITTING ANY NEW IMAGE OR TESTS:**

1. ✅ Build the image: `make build/new-service-X-Y`
2. ✅ Run docker-compose test setup with lagoon images (not uselagoon)
3. ✅ Execute EVERY SINGLE test command manually and verify output
4. ✅ Confirm all grep patterns match actual command output
5. ✅ Test docker ps verification commands
6. ✅ Clean up test environment

**Skipping test validation WILL cause CI failures and break the build pipeline.**

## Complete Service Implementation Workflow

When implementing a new service with multiple variants (like varnish-8), follow this comprehensive workflow:

### 1. Create All Dockerfiles
```bash
# Base service
images/service-X/Y.Dockerfile

# Specialized variants following hierarchy
images/service-X-drupal/Y.Dockerfile     # FROM service-X
images/service-X-persistent/Y.Dockerfile  # FROM service-X  
images/service-X-persistent-drupal/Y.Dockerfile  # FROM service-X-drupal
```

### 2. Update Build System (docker-bake.hcl)
```hcl
# Add base service target
target "service-X" {
  inherits = ["default"]
  context = "images/service"
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
  }
  dockerfile = "X.Dockerfile"
  tags = tags("service-X")
}

# Add specialized variant targets
target "service-X-drupal" {
  inherits = ["default"]
  context = "images/service-drupal"
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
    "${LOCAL_REPO}/service": "target:service-X"
  }
  dockerfile = "X.Dockerfile"
  tags = tags("service-X-drupal")
}

target "service-X-persistent" {
  inherits = ["default"]
  context = "images/service-persistent"
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
    "${LOCAL_REPO}/service": "target:service-X"
  }
  dockerfile = "X.Dockerfile"
  tags = tags("service-X-persistent")
}

target "service-X-persistent-drupal" {
  inherits = ["default"]
  context = "images/service-persistent-drupal"
  contexts = {
    "${LOCAL_REPO}/commons": "target:commons"
    "${LOCAL_REPO}/service-drupal": "target:service-X-drupal"
  }
  dockerfile = "X.Dockerfile"
  tags = tags("service-X-persistent-drupal")
}

# Add all targets to a service-specific group
group "service" {
  targets = [
    "service-X",
    "service-X-drupal",
    "service-X-persistent",
    "service-X-persistent-drupal"
  ]
}

# CRITICAL: Also add all targets to the default group
group "default" {
  targets = [
    "commons",
    # ... existing targets ...
    "service-X",
    "service-X-drupal",
    "service-X-persistent",
    "service-X-persistent-drupal",
    # ... more targets ...
  ]
}
```

### 3. Add Test Infrastructure
```yaml
# helpers/services-docker-compose.yml
service-X:
  image: uselagoon/service-X:latest
  ports:
    - "SERVICE_PORT"
  << : *default-user
  environment:
    - CONFIG_VAR=value
```

### 4. Create Comprehensive Tests
```bash
# Add to TESTING_service_images_dockercompose.md
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep service-X
docker compose exec -T service-X sh -c "version-check" | grep "expected-version"
docker compose exec -T service-X sh -c "functionality-test" | grep "expected-output"
```

### 5. Complete Validation Cycle
```bash
# Build all variants
make build/service-X build/service-X-drupal build/service-X-persistent build/service-X-persistent-drupal

# Test all variants locally
cp helpers/services-docker-compose.yml temp-compose.yml
sed -i 's/uselagoon/lagoon/g' temp-compose.yml
docker compose -f temp-compose.yml up -d service-X commons

# Run every test command manually
docker compose -f temp-compose.yml exec -T service-X test-command | grep expected-output

# Clean up
docker compose -f temp-compose.yml down && rm temp-compose.yml
```

### 6. Git Workflow
```bash
# Commit all changes together
git add images/ docker-bake.hcl helpers/
git commit -m "Add service-X images and comprehensive test suite"
git push origin feature-branch

# Create PR with detailed description of all variants and testing results
```

This workflow ensures consistency, proper dependency management, and comprehensive validation for complex multi-variant service implementations.

## End-of-Life Image Management

When upstream software versions reach end-of-life or become deprecated, follow this process to properly mark images and guide users to supported alternatives.

### Identifying End-of-Life Images

**Common scenarios requiring EOL marking:**
- Upstream software version reaches official end-of-life (e.g., Python 3.10, Node 16)
- Security vulnerabilities with no upstream patches available
- Major version deprecation by upstream maintainers
- Technology stack obsolescence

### Adding End-of-Life Labels

Add deprecation labels immediately after the standard OCI labels in the Dockerfile:

```dockerfile
# Standard OCI labels
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/service/version.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Service X.Y image optimised for running in Lagoon"
LABEL org.opencontainers.image.title="uselagoon/service-X.Y"
LABEL org.opencontainers.image.base.name="docker.io/upstream:X.Y"

# End-of-life deprecation labels
LABEL sh.lagoon.image.deprecated.status="endoflife"
LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/service-Z.W"
```

### Choosing Replacement Versions

**Replacement selection priority:**
1. **Latest LTS/Stable**: Choose the most recent long-term support version
2. **Maximum longevity**: Select versions with longest remaining support lifecycle  
3. **Compatibility**: Ensure reasonable upgrade path exists
4. **Availability**: Verify the suggested replacement exists in lagoon-images

**Examples of good replacement choices:**
- `python-3.10` → `python-3.14` (latest stable with longest support)
- `node-16` → `node-22` (latest LTS with extended support)
- `solr-8` → `solr-9` (next major version)
- `mariadb-10.6` → `mariadb-11.4` (latest stable)

### End-of-Life Label Reference

**Required Labels:**
```dockerfile
LABEL sh.lagoon.image.deprecated.status="endoflife"
LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/recommended-replacement"
```

**Label Definitions:**
- **`sh.lagoon.image.deprecated.status`**: Always set to `"endoflife"` for EOL images
- **`sh.lagoon.image.deprecated.suggested`**: Full image reference for recommended replacement
  - Format: `"docker.io/uselagoon/service-version"`
  - Must point to an image that exists in lagoon-images
  - Should provide the longest support lifecycle available

### Implementation Workflow

1. **Identify EOL Timeline**: Research upstream end-of-life dates and security support
2. **Select Replacement**: Choose the most appropriate long-term replacement version
3. **Verify Availability**: Confirm replacement image exists and builds successfully
4. **Add Labels**: Insert deprecation labels after OCI labels in Dockerfile
5. **Test Build**: Ensure image still builds with new labels
6. **Document Migration**: Consider adding migration notes or documentation

### Example Implementation

**Before (Active Image):**
```dockerfile
FROM python:3.13.9-alpine3.22
# ... standard labels only
ENV LAGOON=python
```

**After (End-of-Life Image):**
```dockerfile
FROM python:3.13.9-alpine3.22
# ... standard OCI labels ...

LABEL sh.lagoon.image.deprecated.status="endoflife"
LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/python-3.14"

ENV LAGOON=python
```

### Integration with Tooling

These labels are consumed by:
- **Container scanners**: Trivy, Syft, Grype detect deprecated images
- **Lagoon platform**: Warning systems and upgrade recommendations  
- **CI/CD pipelines**: Automated detection of deprecated dependencies
- **Documentation**: Automatic generation of migration guides

### Best Practices

✅ **DO:**
- Mark images as EOL immediately when upstream support ends
- Suggest the newest stable version with longest support lifecycle
- Verify replacement images build and function correctly
- Keep existing functionality unchanged (only add labels)

❌ **DON'T:**
- Remove or break existing EOL images (maintain backward compatibility)
- Suggest intermediate versions unless necessary for compatibility
- Add EOL labels without researching proper replacement versions
- Forget to verify the suggested replacement actually exists

This process ensures users receive clear guidance on deprecated images while maintaining system stability during migration periods.

## Complete Image Deprecation Workflow

After marking images as end-of-life with deprecation labels, images may eventually need complete removal from the repository to reduce maintenance overhead and build complexity.

### Full Deprecation Process

**Phase 1: End-of-Life Marking** (See End-of-Life Image Management section above)
1. Add deprecation labels to Dockerfile
2. Keep image functional for backward compatibility
3. Provide clear replacement guidance

**Phase 2: Complete Removal** (After sufficient migration period)
1. **Remove Dockerfile**: Delete `images/service/version.Dockerfile`
2. **Update Build System**: Remove target from docker-bake.hcl and all group definitions
3. **Remove Test Infrastructure**: Remove docker-compose services and test cases
4. **Update Documentation**: Remove references from copilot instructions and examples
5. **Verify Clean Removal**: Ensure no remaining references in repository

### Complete Removal Checklist

**Build System Updates:**
```bash
# Remove from docker-bake.hcl target definitions
# Delete the entire target block for the service

# Remove from docker-bake.hcl group definitions
# Remove target name from any groups (default, service-specific groups)

# Verify removal
make build-list | grep service-X-Y  # Should return nothing
```

**Test Infrastructure Updates:**
```yaml
# Remove from helpers/images-docker-compose.yml or helpers/services-docker-compose.yml
service-X-Y:  # ← Remove entire service definition
  image: uselagoon/service-X-Y:latest
  ports:
    - "PORT"
  << : *default-user
```

**Test Case Removal:**
Remove all test commands from `helpers/TESTING_*_dockercompose.md`:
```bash
# Remove service startup verification
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep service-X-Y

# Remove version checks
docker compose exec -T service-X-Y version-command | grep "X.Y"

# Remove functionality tests
docker compose exec -T service-X-Y functionality-test | grep expected
```

**Documentation Updates:**
- Remove examples from copilot instructions
- Update version ranges in documentation
- Remove deprecated version from upgrade guides

### Validation Commands

**Verify Complete Removal:**
```bash
# Check build system
make build-list | grep service-X-Y  # Should return nothing

# Search for remaining references
grep -r "service-X-Y\|service.*X\.Y" . --exclude-dir=.git --exclude-dir=scans --exclude-dir=build

# Verify file deletion
ls images/service/X-Y.Dockerfile  # Should not exist
```

**Test Build System:**
```bash
# Ensure build system works without removed image
make build/service-related-image  # Should succeed

# Verify dependency resolution
make build-list  # Should show remaining images only
```

### Timeline Considerations

**Minimum Deprecation Period:** 6-12 months between EOL marking and complete removal
**Communication:** Announce removal timeline in release notes and documentation
**Monitoring:** Track usage patterns before removal to ensure safe deprecation

### Example: Python 3.9 Complete Removal

Following the end-of-life marking of Python 3.9, the complete removal process involved:

1. **File Deletion**: `rm images/python/3.9.Dockerfile`
2. **docker-bake.hcl Updates**: Removed `python-3.9` target definition and from `python` and `default` groups
3. **Test Removal**: Removed docker-compose service and all test cases
4. **Documentation**: Updated copilot instruction examples to use Python 3.10+ 
5. **Verification**: Confirmed `make build-list | grep python` shows only supported versions

This demonstrates the complete lifecycle from active image → EOL marking → full removal, ensuring clean repository maintenance while providing users adequate migration time.
