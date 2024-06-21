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

# SOURCE_REPO is the repos where the upstream images are found (usually uselagoon, but can substiture for testlagoon)
UPSTREAM_REPO ?= uselagoon
UPSTREAM_TAG ?= latest

# Local environment
ARCH := $(shell uname | tr '[:upper:]' '[:lower:]')
LAGOON_VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo development )
DOCKER_DRIVER := $(shell docker info -f '{{.Driver}}')

# Name of the Branch we are currently in
BRANCH_NAME := $(shell git rev-parse --abbrev-ref HEAD)
SAFE_BRANCH_NAME := $(shell echo $(BRANCH_NAME) | sed -E 's/[^[:alnum:]_.-]//g' | cut -c 1-128)

PUBLISH_PLATFORM_ARCH := linux/amd64,linux/arm64

# Skip image scanning by default to make building images substantially faster
SCAN_IMAGES := false

# Only set this to false when ready to push images to dockerhub
PUBLISH_IMAGES ?= false

# Init the file that is used to hold the image tag cross-reference table
$(shell >build.txt)
$(shell >scan.txt)

ifeq ($(MACHINE), arm64)
	PLATFORM_ARCH ?= linux/arm64
else
	PLATFORM_ARCH ?= linux/amd64
endif

#######
####### Functions
#######

# Builds a docker image. Expects as arguments: name of the image, location of Dockerfile, path of
# Docker Build Context
docker_build = PLATFORMS=$(PLATFORM_ARCH) IMAGE_REPO=$(CI_BUILD_TAG) UPSTREAM_REPO=$(UPSTREAM_REPO) UPSTREAM_TAG=$(UPSTREAM_TAG) TAG=latest LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake --progress=quiet -f docker-bake.hcl --builder $(CI_BUILD_TAG) --load $(1)

docker_buildx_create = 	docker buildx create --name $(CI_BUILD_TAG) || echo  -e '$(CI_BUILD_TAG) builder already present\n'

scan_cmd = docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(HOME)/Library/Caches:/root/.cache/ aquasec/trivy --timeout 5m0s $(CI_BUILD_TAG)/$(1) >> scan.txt

ifeq ($(SCAN_IMAGES),true)
	scan_image = $(scan_cmd)
else
	scan_image =
endif

.PHONY: docker_pull
docker_pull:
	docker images --format "{{.Repository}}:{{.Tag}}" | grep -E '$(UPSTREAM_REPO)' | grep -E '$(UPSTREAM_TAG)' | xargs -tn1 -P8 docker pull -q || true;
	grep -Eh 'FROM' $$(find . -type f -name *Dockerfile) | grep -Ev '_REPO|_VERSION|_CACHE' | awk '{print $$2}' | sort --unique | xargs -tn1 -P8 docker pull -q

#######
####### Base Images
#######
####### Base Images are the base for all other images and are also published for clients to use during local development

base-images := 	commons \
				mariadb-10.4 \
				mariadb-10.4-drupal \
				mariadb-10.5 \
				mariadb-10.5-drupal \
				mariadb-10.6 \
				mariadb-10.6-drupal \
				mariadb-10.11 \
				mariadb-10.11-drupal \
				mongo-4 \
				mysql-8.0 \
				mysql-8.4 \
				nginx \
				nginx-drupal \
				node-18 \
				node-18-builder \
				node-18-cli \
				node-20 \
				node-20-builder \
				node-20-cli \
				node-22 \
				node-22-builder \
				node-22-cli \
				opensearch-2 \
				php-8.1-fpm \
				php-8.2-fpm \
				php-8.3-fpm \
				php-8.1-cli \
				php-8.2-cli \
				php-8.3-cli \
				php-8.1-cli-drupal \
				php-8.2-cli-drupal \
				php-8.3-cli-drupal \
				postgres-11 \
				postgres-11-ckan \
				postgres-11-drupal \
				postgres-12 \
				postgres-12-drupal \
				postgres-13 \
				postgres-13-drupal \
				postgres-14 \
				postgres-14-drupal \
				postgres-15 \
				postgres-15-drupal \
				postgres-16 \
				postgres-16-drupal \
				python-3.8 \
				python-3.9 \
				python-3.10 \
				python-3.11 \
				python-3.12 \
				rabbitmq \
				redis-6 \
				redis-6-persistent \
				redis-7 \
				redis-7-persistent \
				ruby-3.1 \
				ruby-3.2 \
				ruby-3.3 \
				solr-8 \
				solr-8-drupal \
				solr-9 \
				solr-9-drupal \
				varnish-6 \
				varnish-6-drupal \
				varnish-6-persistent \
				varnish-6-persistent-drupal \
				varnish-7 \
				varnish-7-drupal \
				varnish-7-persistent \
				varnish-7-persistent-drupal \

build-base-images = $(foreach image,$(base-images),build/$(image))

# Recipe for all building service-images
$(build-base-images):
	$(eval image = $(subst build/,,$@))
	$(eval image = $(subst .,-,$(image)))
	$(call docker_buildx_create)
	$(call docker_build,$(image))
	$(call scan_image,$(image))

#######
####### Building Images
#######

# Builds all Images
.PHONY: build
build: $(foreach image,$(base-images) ,build/$(image))

# Outputs a list of all Images we manage
.PHONY: build-list
build-list:
	@for number in $(foreach image,$(base-images) ,build/$(image)); do \
			echo $$number ; \
	done

# Conduct post-release scans on images
.PHONY: scan-images
scan-images:
	rm -f ./scans/*.txt
	@for tag in $(foreach image,$(base-images),$(image)); do \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(HOME)/Library/Caches:/root/.cache/ aquasec/trivy image --timeout 5m0s $(CI_BUILD_TAG)/$$tag > ./scans/$$tag.trivy.txt ; \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft $(CI_BUILD_TAG)/$$tag > ./scans/$$tag.syft.txt ; \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(HOME)/Library/Caches:/var/lib/grype/db anchore/grype --add-cpes-if-none $(CI_BUILD_TAG)/$$tag > ./scans/$$tag.grype.txt ; \
			echo $$tag ; \
	done

#######
####### Publishing Images
#######
####### All main&PR images are pushed to testlagoon repository
#######

.PHONY: publish-testlagoon-images
publish-testlagoon-images:
	PLATFORMS=$(PUBLISH_PLATFORM_ARCH) IMAGE_REPO=docker.io/testlagoon TAG=$(BRANCH_NAME) LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake -f docker-bake.hcl --builder $(CI_BUILD_TAG) --push

# tag and push all images

.PHONY: publish-uselagoon-images
publish-uselagoon-images:
	PLATFORMS=$(PUBLISH_PLATFORM_ARCH) IMAGE_REPO=docker.io/uselagoon TAG=$(LAGOON_VERSION) LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake -f docker-bake.hcl --builder $(CI_BUILD_TAG) --push
	PLATFORMS=$(PUBLISH_PLATFORM_ARCH) IMAGE_REPO=docker.io/uselagoon TAG=latest LAGOON_VERSION=$(LAGOON_VERSION) docker buildx bake -f docker-bake.hcl --builder $(CI_BUILD_TAG) --push

.PHONY: clean
clean:
	rm -rf build/*
	echo -e "use 'make docker_buildx_clean' to remove semi-permanent builder image"

.PHONY: docker_buildx_clean
docker_buildx_clean:
	docker buildx rm $(CI_BUILD_TAG) || echo  -e 'no builder $(CI_BUILD_TAG) found'

# Conduct post-release scans on images
.PHONY: scan-images
scan-images:
	mkdir -p ./scans
	rm -f ./scans/*.txt
	@for tag in $(foreach image,$(base-images) $(service-images) $(task-images),$(image)); do \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(HOME)/Library/Caches:/root/.cache/ aquasec/trivy image --timeout 5m0s $(CI_BUILD_TAG)/$$tag > ./scans/$$tag.trivy.txt ; \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft $(CI_BUILD_TAG)/$$tag > ./scans/$$tag.syft.txt ; \
			docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(HOME)/Library/Caches:/var/lib/grype/db anchore/grype $(CI_BUILD_TAG)/$$tag > ./scans/$$tag.grype.txt ; \
			echo $$tag ; \
	done

#######
####### Transferring Images to S3
#######

s3-save = $(foreach image,$(s3-images),[s3-save]-$(image))
# save all images to s3
.PHONY: s3-save
s3-save: $(s3-save)
# tag and push of each image
.PHONY: $(s3-save)
$(s3-save):
#   remove the prefix '[s3-save]-' first
		$(eval image = $(subst [s3-save]-,,$@))
		$(eval image = $(subst __,:,$(image)))
		docker save $(CI_BUILD_TAG)/$(image) $$(docker history -q $(CI_BUILD_TAG)/$(image) | grep -v missing) | gzip -9 | aws s3 cp - s3://lagoon-images/$(image).tar.gz

s3-load = $(foreach image,$(s3-images),[s3-load]-$(image))
# save all images to s3
.PHONY: s3-load
s3-load: $(s3-load)
# tag and push of each image
.PHONY: $(s3-load)
$(s3-load):
#   remove the prefix '[s3-load]-' first
		$(eval image = $(subst [s3-load]-,,$@))
		$(eval image = $(subst __,:,$(image)))
		curl -s https://s3.us-east-2.amazonaws.com/lagoon-images/$(image).tar.gz | gunzip -c | docker load

# Clean all build touches, which will case make to rebuild the Docker Images (Layer caching is
# still active, so this is a very safe command)

.PHONY: docker-buildx-remove
docker-buildx-remove:
	docker buildx rm $(CI_BUILD_TAG) || echo "no buildx cache"
	docker buildx ls
	docker context ls

clean:
	rm -rf build/*
