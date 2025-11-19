SHELL := /bin/bash
# Lagoon Images Makefile The main purpose of this Makefile is to provide easier handling of
# building images and running tests It understands the relation of the different images (like
# nginx-drupal is based on nginx) and builds them in the correct order Also it knows which
# services in docker-compose.yml are depending on which base images or maybe even other service
# images
#
# The main commands are:

# make build/<imagename>
# Builds an individual image and all of it's needed parents. Run `make build-list` to get a list of
# all buildable images. Make will keep track of each build image with creating an empty file with
# the name of the image in the folder `build`. If you want to force a rebuild of the image, either
# remove that file or run `make clean`

# make build
# builds all images in the correct order. Uses existing images for layer caching, define via `TAG`
# which branch should be used

# make tests/<testname>
# Runs individual tests. In a nutshell it does:
# 1. Builds all needed images for the test
# 2. Starts needed Lagoon services for the test via docker-compose up
# 3. Executes the test
#
# Run `make tests-list` to see a list of all tests.

# make tests
# Runs all tests together. Can be executed with `-j2` for two parallel running tests

# make up
# Starts all Lagoon Services at once, useful for local development or just to start all of them.

# make logs
# Shows logs of Lagoon Services (aka docker-compose logs -f)

#######
####### Default Variables
#######

# Parameter for all `docker build` commands, can be overwritten by passing `DOCKER_BUILD_PARAMS=` via the `-e` option
DOCKER_BUILD_PARAMS :=

# On CI systems like jenkins we need a way to run multiple testings at the same time. We expect the
# CI systems to define an Environment variable CI_BUILD_TAG which uniquely identifies each build.
# If it's not set we assume that we are running local and just call it lagoon.
CI_BUILD_TAG ?= lagoon

# Local environment
ARCH := $(shell uname | tr '[:upper:]' '[:lower:]')
LAGOON_VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo development )

# Name of the Branch we are currently in
BRANCH_NAME :=

PUBLISH_PLATFORM_ARCH := linux/amd64,linux/arm64

ifeq ($(MACHINE), arm64)
	PLATFORM_ARCH ?= linux/arm64
else
	PLATFORM_ARCH ?= linux/amd64
endif

# Set parallelism to two less than the total number of processors
BUILDKIT_PARALLELISM := $(shell echo $$(($(shell nproc) - 2)))

# Init the file that is used to hold the image tag cross-reference table
$(shell >build.txt)
$(shell >scan.txt)

#######
####### Functions
#######

# Builds a docker image. Expects as arguments: name of the image, location of Dockerfile, path of
# Docker Build Context
docker_build = PLATFORMS=$(PLATFORM_ARCH) IMAGE_REPO=$(CI_BUILD_TAG) UPSTREAM_REPO=$(UPSTREAM_REPO) UPSTREAM_TAG=$(UPSTREAM_TAG) TAG=latest LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake -f docker-bake.hcl --builder ci-lagoon-images $(1)

.PHONY: docker_buildx_create
docker_buildx_create:
	@if ! docker buildx ls | grep -q "ci-lagoon-images"; then \
		docker buildx create --platform linux/arm64,linux/arm/v8 --driver-opt network=host --name ci-lagoon-images --buildkitd-flags '--oci-max-parallelism=$(BUILDKIT_PARALLELISM)'; \
	else \
		echo "ci-lagoon-images builder already exists"; \
	fi

#######
####### Building Images
#######

# Builds all Images
.PHONY: build
build: docker_buildx_create
	$(call docker_build,default --load)

# Builds all Images in the background, without loading or pushing them
.PHONY: build-bg
build-bg: docker_buildx_create
	$(call docker_build,default)

# Build individual images with specific targets
build/%: docker_buildx_create
	$(call docker_build,$* --load)

# Outputs a list of all Images we manage
.PHONY: build-list
build-list:
	$(call docker_build,--print) | jq -r '.target | keys[] | "build/"+.'

# Outputs a list of all Images we manage
.PHONY: build-tags
build-tags:
	@$(call docker_build,--print) | jq -r '.target | .[].tags[]'

# Conduct post-release scans on images
.PHONY: scan-images
scan-images:
	rm -f ./scans/*.txt
	@for tag in $(shell $(MAKE) build-tags); do \
			tag_name=$$(echo $$tag | sed 's|.*/\([^:]*\):.*|\1|'); \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(HOME)/Library/Caches:/root/.cache/ aquasec/trivy image --timeout 5m0s $$tag > ./scans/$$tag_name.trivy.txt ; \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft $$tag > ./scans/$$tag_name.syft.txt ; \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(HOME)/Library/Caches:/var/lib/grype/db anchore/grype --add-cpes-if-none $$tag > ./scans/$$tag_name.grype.txt ; \
			echo $$tag ; \
	done

#######
####### Publishing Images
#######
####### All main&PR images are pushed to testlagoon repository
#######

.PHONY: publish-testlagoon-images
publish-testlagoon-images:
	PLATFORMS=$(PUBLISH_PLATFORM_ARCH) IMAGE_REPO=docker.io/testlagoon TAG=$(BRANCH_NAME) LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake -f docker-bake.hcl --builder ci-lagoon-images --push

# tag and push all images

.PHONY: publish-uselagoon-images
publish-uselagoon-images:
	PLATFORMS=$(PUBLISH_PLATFORM_ARCH) IMAGE_REPO=docker.io/uselagoon TAG=$(LAGOON_VERSION) LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake -f docker-bake.hcl --builder ci-lagoon-images --push
	PLATFORMS=$(PUBLISH_PLATFORM_ARCH) IMAGE_REPO=docker.io/uselagoon TAG=latest LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake -f docker-bake.hcl --builder ci-lagoon-images --push

.PHONY: docker_buildx_clean
docker_buildx_clean:
	docker buildx rm ci-lagoon-images || echo "no buildx cache"
	docker buildx ls
	docker context ls
