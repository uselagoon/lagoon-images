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
DESTINATION_REPO ?= testlagoon
DESTINATION_TAG ?= latest

# Local environment
ARCH := $(shell uname | tr '[:upper:]' '[:lower:]')
LAGOON_VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo development )
DOCKER_DRIVER := $(shell docker info -f '{{.Driver}}')

# Name of the Branch we are currently in
BRANCH_NAME :=

# Only set this to false when ready to push images to dockerhub
PUBLISH_IMAGES ?= false

PLATFORM ?= linux/amd64

# Init the file that is used to hold the image tag cross-reference table
$(shell >build.txt)
$(shell >scan.txt)

#######
####### Functions
#######

# Builds a docker image. Expects as arguments: name of the image, location of Dockerfile, path of
# Docker Build Context
docker_build_local = DOCKER_BUILDKIT=1 docker build $(DOCKER_BUILD_PARAMS) \
						--build-arg BUILDKIT_INLINE_CACHE=1 \
						--cache-from testlagoon/$(1):main \
						--build-arg LAGOON_VERSION=$(LAGOON_VERSION) \
						--build-arg IMAGE_REPO=$(CI_BUILD_TAG) \
						-t $(CI_BUILD_TAG)/$(1) \
						-f $(2) $(3)

docker_buildx_two = docker buildx build $(DOCKER_BUILD_PARAMS) \
						--builder ci-local \
						--platform $(PLATFORM) \
						--build-arg BUILDKIT_INLINE_CACHE=1 \
						--build-arg LAGOON_VERSION=$(LAGOON_VERSION) \
						--build-arg IMAGE_REPO=localhost:5000/testlagoon \
						--pull \
						--cache-from=type=registry,ref=localhost:5000/testlagoon/$(1) \
						--push \
						-t localhost:5000/testlagoon/$(1) \
						-t $(REGISTRY_ONE)/$(1):$(TAG_ONE) \
						-t $(REGISTRY_TWO)/$(1):$(TAG_TWO) \
						-f $(2) $(3)

docker_buildx_three = docker buildx build $(DOCKER_BUILD_PARAMS) \
						--builder ci-local \
						--platform $(PLATFORM) \
						--build-arg BUILDKIT_INLINE_CACHE=1 \
						--build-arg LAGOON_VERSION=$(LAGOON_VERSION) \
						--build-arg IMAGE_REPO=localhost:5000/uselagoon \
						--pull \
						--cache-from=type=registry,ref=localhost:5000/testlagoon/$(1) \
						--push \
						-t localhost:5000/uselagoon/$(1) \
						-t uselagoon/$(1)-test:$(LAGOON_VERSION) \
						-t uselagoon/$(1)-test:latest \
						-t testlagoon/$(1)-test:$(BRANCH_NAME) \
						-f $(2) $(3)

ifeq ($(PUBLISH_IMAGES),true)
	ifdef REGISTRY_THREE
		docker_build = $(docker_buildx_three)
	else ifdef REGISTRY_TWO
		docker_build = $(docker_buildx_two)
	else ifdef REGISTRY_ONE
		docker_build = $(docker_buildx_one)
	endif
else
	docker_build = $(docker_build_local)
endif


# Tags an image with the `testlagoon` repository and pushes it
docker_publish_testlagoon = docker tag $(CI_BUILD_TAG)/$(1) testlagoon/$(2) && docker push testlagoon/$(2) | cat

# Tags an image with the `uselagoon` repository and pushes it
docker_publish_uselagoon = docker tag $(CI_BUILD_TAG)/$(1) uselagoon/$(2) && docker push uselagoon/$(2) | cat

.PHONY: docker_pull
docker_pull:
	grep -Eh 'FROM' $$(find . -type f -name *Dockerfile) | grep -Ev 'IMAGE_REPO' | sed 's/\-\-platform\=linux\/amd64//g' | awk '{print $$2}' | sort --unique | xargs -tn1 -P8 docker pull -q

#######
####### Base Images
#######
####### Base Images are the base for all other images and are also published for clients to use during local development

unversioned-images :=		commons \
							nginx \
							nginx-drupal \
							rabbitmq \
							rabbitmq-cluster

# base-images is a variable that will be constantly filled with all base image there are
base-images += $(unversioned-images)

# List with all images prefixed with `build/`. Which are the commands to actually build images
build-images = $(foreach image,$(unversioned-images),build/$(image))

# Define the make recipe for all base images
$(build-images):
#	Generate variable image without the prefix `build/`
	$(eval image = $(subst build/,,$@))
# Call the docker build
	$(call docker_build,$(image),images/$(image)/Dockerfile,images/$(image))
# Populate the cross-reference table
	$(shell echo $(shell date +"%T") $(image),images/$(image)/Dockerfile,images/$(image) >> build.txt)
#scan created image with Trivy
#	$(call scan_image,$(image),)
# Touch an empty file which make itself is using to understand when the image has been last build
#	touch $@

# Define dependencies of Base Images so that make can build them in the right order. There are two
# types of Dependencies
# 1. Parent Images, like `build/centos7-node6` is based on `build/centos7` and need to be rebuild
#    if the parent has been built
# 2. Dockerfiles of the Images itself, will cause make to rebuild the images if something has
#    changed on the Dockerfiles
build/commons: images/commons/Dockerfile
build/nginx: build/commons images/nginx/Dockerfile
build/nginx-drupal: build/nginx images/nginx-drupal/Dockerfile
build/rabbitmq: build/commons images/rabbitmq/Dockerfile
build/rabbitmq-cluster: build/rabbitmq images/rabbitmq-cluster/Dockerfile

#######
####### Multi-version Images
#######

versioned-images := 		mariadb-10.6 \
							mariadb-10.6-drupal \
							mariadb-10.11 \
							mariadb-10.11-drupal \
							mariadb-11.4 \
							mongo-4 \
							mysql-8.0 \
							mysql-8.4 \
							node-20 \
							node-20-builder \
							node-20-cli \
							node-22 \
							node-22-builder \
							node-22-cli \
							node-24 \
							node-24-builder \
							node-24-cli \
							opensearch-2 \
							opensearch-3 \
							php-8.1-fpm \
							php-8.1-cli \
							php-8.1-cli-drupal \
							php-8.2-fpm \
							php-8.2-cli \
							php-8.2-cli-drupal \
							php-8.3-fpm \
							php-8.3-cli \
							php-8.3-cli-drupal \
							php-8.4-fpm \
							php-8.4-cli \
							php-8.4-cli-drupal \
							postgres-13 \
							postgres-13-drupal \
							postgres-14 \
							postgres-14-drupal \
							postgres-15 \
							postgres-15-drupal \
							postgres-16 \
							postgres-16-drupal \
							postgres-17 \
							postgres-17-drupal \
							python-3.9 \
							python-3.10 \
							python-3.11 \
							python-3.12 \
							python-3.13 \
							redis-7 \
							redis-7-persistent \
							redis-8 \
							ruby-3.2 \
							ruby-3.3 \
							ruby-3.4 \
							solr-9 \
							solr-9-drupal \
							valkey-8 \
							varnish-6 \
							varnish-6-drupal \
							varnish-6-persistent \
							varnish-6-persistent-drupal \
							varnish-7 \
							varnish-7-drupal \
							varnish-7-persistent \
							varnish-7-persistent-drupal

build-versioned-images = $(foreach image,$(versioned-images),build/$(image))

# Define the make recipe for all multi images
$(build-versioned-images):
	$(eval image = $(subst build/,,$@))
	$(eval variant = $(word 1,$(subst -, ,$(image))))
	$(eval version = $(word 2,$(subst -, ,$(image))))
	$(eval type = $(word 3,$(subst -, ,$(image))))
	$(eval subtype = $(word 4,$(subst -, ,$(image))))
# Construct the folder and legacy tag to use - note that if treats undefined vars as 'false' to avoid extra '-/'
	$(eval folder = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
# Call the generic docker build process
	$(call docker_build,$(image),images/$(folder)/$(if $(version),$(version).)Dockerfile,images/$(folder))
# Populate the cross-reference table
	$(shell echo $(shell date +"%T") $(image),images/$(folder)/$(if $(version),$(version).)Dockerfile,images/$(folder) >> build.txt)
#scan created images with Trivy
#	$(call scan_image,$(image),)
# Touch an empty file which make itself is using to understand when the image has been last built
#	touch $@

base-images-with-versions += $(versioned-images)

build/mariadb-10.6 build/mariadb-10.11 build/mariadb-11.4: build/commons
build/mariadb-10.6-drupal: build/mariadb-10.6
build/mariadb-10.11-drupal: build/mariadb-10.11
build/mongo-4: build/commons
build/mysql-8.0 build/mysql-8.4: build/commons
build/node-20 build/node-22 build/node-24: build/commons
build/node-20-builder build/node-20-cli: build/node-20
build/node-22-builder build/node-22-cli: build/node-22
build/node-24-builder build/node-24-cli: build/node-24
build/opensearch-2: build/commons
build/opensearch-3: build/commons
build/php-8.1-fpm build/php-8.2-fpm build/php-8.3-fpm build/php-8.4-fpm: build/commons
build/php-8.1-cli: build/php-8.1-fpm
build/php-8.1-cli-drupal: build/php-8.1-cli
build/php-8.2-cli: build/php-8.2-fpm
build/php-8.2-cli-drupal: build/php-8.2-cli
build/php-8.3-cli: build/php-8.3-fpm
build/php-8.3-cli-drupal: build/php-8.3-cli
build/php-8.4-cli: build/php-8.4-fpm
build/php-8.4-cli-drupal: build/php-8.4-cli
build/postgres-13 build/postgres-14 build/postgres-15 build/postgres-16 build/postgres-17: build/commons
build/postgres-13-drupal: build/postgres-13
build/postgres-14-drupal: build/postgres-14
build/postgres-15-drupal: build/postgres-15
build/postgres-16-drupal: build/postgres-16
build/postgres-17-drupal: build/postgres-17
build/python-3.9 build/python-3.10 build/python-3.11 build/python-3.12 build/python-3.13: build/commons
build/redis-7 build/redis-8: build/commons
build/redis-7-persistent: build/redis-7
build/ruby-3.2 build/ruby-3.3 build/ruby-3.4: build/commons
build/solr-9: build/commons
build/solr-9-drupal: build/solr-9
build/valkey-8: build/commons
build/varnish-6 build/varnish-7: build/commons
build/varnish-6-drupal build/varnish-6-persistent: build/varnish-6
build/varnish-6-persistent-drupal: build/varnish-6-drupal
build/varnish-7-drupal build/varnish-7-persistent: build/varnish-7
build/varnish-7-persistent-drupal: build/varnish-7-drupal

#######
####### Building Images
#######

# Builds all Images
.PHONY: build
build: $(foreach image,$(base-images) $(base-images-with-versions) ,build/$(image))
	cat build.txt

# Outputs a list of all Images we manage
.PHONY: build-list
build-list:
	@for number in $(foreach image,$(base-images) $(base-images-with-versions),build/$(image)); do \
			echo $$number ; \
	done

# Conduct post-release scans on images
.PHONY: scan-images
scan-images:
	rm -f ./scans/*.txt
	@for tag in $(foreach image,$(base-images) $(base-images-with-versions),$(image)); do \
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

.PHONY: docker-buildx-configure
docker-buildx-configure:
	docker run -d -p 5000:5000 --restart always --name registry registry:2
	docker buildx create --platform linux/arm64,linux/arm/v8 --driver-opt network=host --name ci-local
	docker buildx ls
	docker context ls

# Publish command to testlagoon docker hub, done on any main branch or PR
publish-testlagoon-baseimages = $(foreach image,$(base-images),[publish-testlagoon-baseimages]-$(image))
publish-testlagoon-baseimages-with-versions = $(foreach image,$(base-images-with-versions),[publish-testlagoon-baseimages-with-versions]-$(image))

# tag and push all images
.PHONY: publish-testlagoon-baseimages
publish-testlagoon-baseimages: $(publish-testlagoon-baseimages) $(publish-testlagoon-baseimages-with-versions) $(publish-testlagoon-baseimages-without-versions) $(publish-testlagoon-experimental-baseimages)

# tag and push of each image
.PHONY: $(publish-testlagoon-baseimages)
$(publish-testlagoon-baseimages):
# Calling docker_publish for image, but remove the prefix '[publish-testlagoon-baseimages]-' first
		$(eval image = $(subst [publish-testlagoon-baseimages]-,,$@))
		$(eval variant = $(word 1,$(subst -, ,$(image))))
		$(eval version = $(word 2,$(subst -, ,$(image))))
		$(eval type = $(word 3,$(subst -, ,$(image))))
		$(eval subtype = $(word 4,$(subst -, ,$(image))))
# Construct the folder and legacy tag to use - note that if treats undefined vars as 'false' to avoid extra '-/'
		$(eval folder = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
# We publish these images with the branch_name/PR no/tag
		$(call docker_publish_testlagoon,$(image),$(image):$(BRANCH_NAME),$(folder))

# tag and push of base image with version
.PHONY: $(publish-testlagoon-baseimages-with-versions)
$(publish-testlagoon-baseimages-with-versions):
# Calling docker_publish for image, but remove the prefix '[publish-testlagoon-baseimages-with-versions]-' first
		$(eval image = $(subst [publish-testlagoon-baseimages-with-versions]-,,$@))
# The underline is a placeholder for a colon, replace that
		$(eval image = $(subst __,:,$(image)))
		$(eval variant = $(word 1,$(subst -, ,$(image))))
		$(eval version = $(word 2,$(subst -, ,$(image))))
		$(eval type = $(word 3,$(subst -, ,$(image))))
		$(eval subtype = $(word 4,$(subst -, ,$(image))))
# Construct the folder and legacy tag to use - note that if treats undefined vars as 'false' to avoid extra '-/'
		$(eval folder = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
# We publish these images with the branch_name/PR no/tag
		$(call docker_publish_testlagoon,$(image),$(image):$(BRANCH_NAME),$(folder))

# tag and push of unversioned base images
.PHONY: $(publish-testlagoon-baseimages-without-versions)
$(publish-testlagoon-baseimages-without-versions):
# Calling docker_publish for image, but remove the prefix '[publish-testlagoon-baseimages-with-versions]-' first
		$(eval image = $(subst [publish-testlagoon-baseimages-without-versions]-,,$@))
		$(eval variant = $(word 1,$(subst -, ,$(image))))
		$(eval version = $(word 2,$(subst -, ,$(image))))
		$(eval type = $(word 3,$(subst -, ,$(image))))
		$(eval subtype = $(word 4,$(subst -, ,$(image))))
# Construct a "legacy" tag of the form `testlagoon/variant-type-subtype` e.g. `testlagoon/postgres-ckan`
		$(eval legacytag = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
# Construct the folder and legacy tag to use - note that if treats undefined vars as 'false' to avoid extra '-/'
		$(eval folder = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
# These images already use a tag to differentiate between different versions of the service itself (like node:14 and node:16)
# We push a version without the `-latest` suffix
		$(call docker_publish_testlagoon,$(image),$(legacytag):$(BRANCH_NAME),$(folder))

# tag and push of experimental base images
.PHONY: publish-testlagoon-experimental-baseimages
publish-testlagoon-experimental-baseimages: $(publish-testlagoon-experimental-baseimages)

.PHONY: $(publish-testlagoon-experimental-baseimages)
$(publish-testlagoon-experimental-baseimages):
# Calling docker_publish for image, but remove the prefix '[publish-testlagoon-baseimages-with-versions]-' first
		$(eval image = $(subst [publish-testlagoon-experimental-baseimages]-,,$@))
# The underline is a placeholder for a colon, replace that
		$(eval image = $(subst __,:,$(image)))
		$(eval variant = $(word 1,$(subst -, ,$(image))))
		$(eval version = $(word 2,$(subst -, ,$(image))))
		$(eval type = $(word 3,$(subst -, ,$(image))))
		$(eval subtype = $(word 4,$(subst -, ,$(image))))
# Construct the folder and legacy tag to use - note that if treats undefined vars as 'false' to avoid extra '-/'
		$(eval folder = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
# We also publish experimental images with an `:experimental` moving tag
		$(call docker_publish_testlagoon,$(image),$(image):experimental,$(folder))

#######
####### All tagged releases are pushed to uselagoon repository with new semantic tags
#######

# Publish command to uselagoon docker hub, only done on tags
publish-uselagoon-baseimages = $(foreach image,$(base-images),[publish-uselagoon-baseimages]-$(image))
publish-uselagoon-baseimages-with-versions = $(foreach image,$(base-images-with-versions),[publish-uselagoon-baseimages-with-versions]-$(image))

# tag and push all images
.PHONY: publish-uselagoon-baseimages
publish-uselagoon-baseimages: $(publish-uselagoon-baseimages) $(publish-uselagoon-baseimages-with-versions)

# tag and push of each image
.PHONY: $(publish-uselagoon-baseimages)
$(publish-uselagoon-baseimages):
#   Calling docker_publish for image, but remove the prefix '[publish-uselagoon-baseimages]-' first
		$(eval image = $(subst [publish-uselagoon-baseimages]-,,$@))
# 	Publish images as :latest
		$(call docker_publish_uselagoon,$(image),$(image):latest)
# 	Publish images with version tag
		$(call docker_publish_uselagoon,$(image),$(image):$(LAGOON_VERSION))

# tag and push of base image with version
.PHONY: $(publish-uselagoon-baseimages-with-versions)
$(publish-uselagoon-baseimages-with-versions):
#   Calling docker_publish for image, but remove the prefix '[publish-uselagoon-baseimages-with-versions]-' first
		$(eval image = $(subst [publish-uselagoon-baseimages-with-versions]-,,$@))
# 	Publish images as :latest
		$(call docker_publish_uselagoon,$(image),$(image):latest)
#	Publish images with version tag
		$(call docker_publish_uselagoon,$(image),$(image):$(LAGOON_VERSION))


# Clean all build touches, which will case make to rebuild the Docker Images (Layer caching is
# still active, so this is a very safe command)

.PHONY: docker-buildx-remove
docker-buildx-remove:
	docker stop registry || echo "no registry"
	docker rm registry || echo "no registry"
	docker buildx rm ci-local || echo "no buildx cache"
	docker buildx ls
	docker context ls

clean:
	rm -rf build/*
