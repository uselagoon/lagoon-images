# Lagoon Base Images - AI Agent Instructions

This repository builds Docker base images for Lagoon - a Drupal & PHP hosting platform optimized for Kubernetes.

## Architecture Overview

### Image Hierarchy & Dependencies
- **commons**: Foundation Alpine-based image with shared utilities (`/lagoon/`, `fix-permissions`, `tini`, etc.)
- **Base images**: Direct children of commons (nginx, php-fpm, node, python, etc.)  
- **Specialized images**: Built on base images (nginx-drupal, php-cli-drupal, varnish-drupal)
- **Multi-version images**: Multiple versions per service (php-8.1-fpm, php-8.2-fpm, node-20, node-22, etc.)

Image names follow pattern: `{service}-{version}[-variant][-specialization]`
Examples: `php-8.3-fpm`, `node-22-builder`, `varnish-6-drupal`, `varnish-8-persistent-drupal`

### Critical Build Dependencies (Makefile)
```makefile
build/nginx-drupal: build/nginx
build/php-8.3-cli: build/php-8.3-fpm  
build/php-8.3-cli-drupal: build/php-8.3-cli
build/varnish-6-drupal: build/varnish-6
build/varnish-8-drupal build/varnish-8-persistent: build/varnish-8
build/varnish-8-persistent-drupal: build/varnish-8-drupal
```

All versioned images depend on `build/commons` as the foundation.

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

# Multi-platform builds (CI only)
make docker-buildx-configure
make build PUBLISH_IMAGES=true PLATFORM='linux/amd64,linux/arm64/v8'
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

**Variant Dependency Pattern:**
```makefile
# Base service depends on commons
build/service-X: build/commons

# Specialized variants depend on base service
build/service-X-drupal build/service-X-persistent: build/service-X

# Combined variants depend on first specialization
build/service-X-persistent-drupal: build/service-X-drupal
```

### Dockerfile Conventions
All Dockerfiles start with:
```dockerfile
ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons
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

### Makefile Image Parsing Logic
Complex variable expansion for versioned images:
```makefile
$(eval variant = $(word 1,$(subst -, ,$(image))))    # php
$(eval version = $(word 2,$(subst -, ,$(image))))    # 8.3  
$(eval type = $(word 3,$(subst -, ,$(image))))       # fpm
$(eval subtype = $(word 4,$(subst -, ,$(image))))    # drupal
$(eval folder = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
```

### Environment Variables & Configuration
- `LAGOON_VERSION`: Git tag or "development"  
- `CI_BUILD_TAG`: Unique identifier for CI builds
- `IMAGE_REPO`: Base repository for parent images (lagoon/testlagoon/uselagoon)
- Development images enable xdebug, have higher memory limits
- Production images disable debug features, enforce stricter security

### Security & Vulnerability Scanning
Post-build scanning with Trivy, Syft, and Grype:
```bash
make scan-images  # Outputs to ./scans/*.{trivy,syft,grype}.txt
```

## Key Files & Integration Points

### Critical Build Files
- `Makefile`: Central build orchestration with complex dependency handling
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
1. `versioned-images` variable in Makefile (add to the list)
2. Dependency declarations in Makefile (add to existing dependency line, e.g., `build/python-3.9 build/python-3.10 ... build/python-3.14: build/commons`)
3. New Dockerfile in appropriate subdirectory
4. Test coverage in helper files

**Critical Makefile Pattern**: Most services follow the pattern where all versions depend on commons:
- `build/python-3.9 build/python-3.10 ... build/python-3.14: build/commons`
- `build/node-20 build/node-22 build/node-24: build/commons`
- `build/ruby-3.2 build/ruby-3.3 build/ruby-3.4: build/commons`

**CRITICAL: When adding new service versions, you must make BOTH Makefile changes:**
1. Add `new-service-X.Y` to the `versioned-images` list
2. Add `build/new-service-X.Y` to the existing dependency line (e.g., add `build/python-3.14` to `build/python-3.9 build/python-3.10 ... build/python-3.14: build/commons`)

When adding new images, follow the established naming and dependency patterns. The Makefile automatically handles complex multi-version builds through variable parsing and dependency resolution.

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

### 2. Update Build System
```makefile
# Add to versioned-images list
service-X \
service-X-drupal \
service-X-persistent \
service-X-persistent-drupal

# Add dependency declarations
build/service-X: build/commons
build/service-X-drupal build/service-X-persistent: build/service-X
build/service-X-persistent-drupal: build/service-X-drupal
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
git add images/ Makefile helpers/
git commit -m "Add service-X images and comprehensive test suite"
git push origin feature-branch

# Create PR with detailed description of all variants and testing results
```

This workflow ensures consistency, proper dependency management, and comprehensive validation for complex multi-variant service implementations.
