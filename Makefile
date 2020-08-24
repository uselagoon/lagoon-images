SHELL := /bin/bash
# amazee.io lagoon Makefile The main purpose of this Makefile is to provide easier handling of
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
# Starts all Lagoon Services at once, usefull for local development or just to start all of them.

# make logs
# Shows logs of Lagoon Services (aka docker-compose logs -f)

#######
####### Default Variables
#######

# Parameter for all `docker build` commands, can be overwritten by passing `DOCKER_BUILD_PARAMS=` via the `-e` option
DOCKER_BUILD_PARAMS := --quiet

# On CI systems like jenkins we need a way to run multiple testings at the same time. We expect the
# CI systems to define an Environment variable CI_BUILD_TAG which uniquely identifies each build.
# If it's not set we assume that we are running local and just call it lagoon.
CI_BUILD_TAG ?= lagoon
BASE_IMAGE_REPO ?= lagoon
BASE_IMAGE_TAG ?= master

# Local environment
ARCH := $(shell uname | tr '[:upper:]' '[:lower:]')
LAGOON_VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo development)
LAGOON_TAG := $(shell git describe --tags --exact-match 2>/dev/null)
DOCKER_DRIVER := $(shell docker info -f '{{.Driver}}')

# Version and Hash of the k8s tools that should be downloaded
K3S_VERSION := v1.17.9-k3s1
KUBECTL_VERSION := v1.17.9
HELM_VERSION := v3.2.4
K3D_VERSION := 1.7.0

# k3d has a 35-char name limit
K3D_NAME := k3s-$(shell echo $(CI_BUILD_TAG) | sed -E 's/.*(.{31})$$/\1/')

# Name of the Branch we are currently in
BRANCH_NAME :=
DEFAULT_ALPINE_VERSION := 3.11


# Init the file that is used to hold the image tag cross-reference table
$(shell >build.txt)
$(shell >scan.txt)

#######
####### Functions
#######

# Builds a docker image. Expects as arguments: name of the image, location of Dockerfile, path of
# Docker Build Context
docker_build = docker build $(DOCKER_BUILD_PARAMS) --build-arg LAGOON_VERSION=$(LAGOON_VERSION) --build-arg IMAGE_REPO=$(CI_BUILD_TAG) --build-arg ALPINE_VERSION=$(DEFAULT_ALPINE_VERSION) -t $(CI_BUILD_TAG)/$(1) -f $(2) $(3)

scan_image = trivy image $(CI_BUILD_TAG)/$(1) >> scan.txt

# Tags an image with the `amazeeio` repository and pushes it
docker_publish_amazeeio = docker tag $(CI_BUILD_TAG)/$(1) amazeeio/$(2) && docker push amazeeio/$(2) | cat

# Tags an image with the `amazeeiolagoon` repository and pushes it
docker_publish_amazeeiolagoon = docker tag $(CI_BUILD_TAG)/$(1) amazeeiolagoon/$(2) && docker push amazeeiolagoon/$(2) | cat

#######
####### Base Images
#######
####### Base Images are the base for all other images and are also published for clients to use during local development

consumer-images :=     commons \
							mariadb \
							mariadb-drupal \
							mongo \
							nginx \
							nginx-drupal \
							varnish \
							varnish-drupal \
							varnish-persistent \
							varnish-persistent-drupal \
							athenapdf-service \
							toolbox

# base-images is a variable that will be constantly filled with all base image there are
base-images += $(consumer-images)
s3-images += $(consumer-images)

# List with all images prefixed with `build/`. Which are the commands to actually build images
build-images = $(foreach image,$(consumer-images),build/$(image))

# Define the make recipe for all base images
$(build-images):
#	Generate variable image without the prefix `build/`
	$(eval image = $(subst build/,,$@))
# Call the docker build
	$(call docker_build,$(image),images/$(image)/Dockerfile,images/$(image))
# Populate the cross-reference table
	$(shell echo $(image),$(image) >> build.txt)
#scan created image with Trivy
	$(call scan_image,$(image),)

# Touch an empty file which make itself is using to understand when the image has been last build
	touch $@

# Define dependencies of Base Images so that make can build them in the right order. There are two
# types of Dependencies
# 1. Parent Images, like `build/centos7-node6` is based on `build/centos7` and need to be rebuild
#    if the parent has been built
# 2. Dockerfiles of the Images itself, will cause make to rebuild the images if something has
#    changed on the Dockerfiles
build/commons: images/commons/Dockerfile
build/mariadb: build/commons images/mariadb/Dockerfile
build/mariadb-drupal: build/mariadb images/mariadb-drupal/Dockerfile
build/mongo: build/commons images/mongo/Dockerfile
build/nginx: build/commons images/nginx/Dockerfile
build/nginx-drupal: build/nginx images/nginx-drupal/Dockerfile
build/varnish: build/commons images/varnish/Dockerfile
build/varnish-drupal: build/varnish images/varnish-drupal/Dockerfile
build/varnish-persistent: build/varnish images/varnish/Dockerfile
build/varnish-persistent-drupal: build/varnish-drupal images/varnish-drupal/Dockerfile
build/docker-host: build/commons images/docker-host/Dockerfile
build/athenapdf-service: build/commons images/athenapdf-service/Dockerfile
build/toolbox: build/commons build/mariadb images/toolbox/Dockerfile
build/kubectl-build-deploy-dind: build/kubectl images/kubectl-build-deploy-dind

#######
####### Multi-version Images
#######

multiimages := 	php-7.2-fpm \
				php-7.3-fpm \
				php-7.4-fpm \
				php-7.2-cli \
				php-7.3-cli \
				php-7.4-cli \
				php-7.2-cli-drupal \
				php-7.3-cli-drupal \
				php-7.4-cli-drupal \
				python-2.7 \
				python-3.7 \
				python-3.8 \
				python-3.9.0rc1 \
				python-2.7-ckan \
				python-2.7-ckandatapusher \
				node-10 \
				node-12 \
				node-14 \
				node-10-builder \
				node-12-builder \
				node-14-builder \
				solr-5.5 \
				solr-6.6 \
				solr-7.7 \
				solr-5.5-drupal \
				solr-6.6-drupal \
				solr-7.7-drupal \
				solr-5.5-ckan \
				solr-6.6-ckan \
				elasticsearch-6 \
				elasticsearch-7 \
				kibana-6 \
				kibana-7 \
				logstash-6 \
				logstash-7 \
				postgres-12 \
				redis-6 \
				redis-6-persistent

verimages := 	postgres-11 \
				postgres-11-ckan \
				postgres-11-drupal \
				redis-5 \
				redis-5-persistent

build-multiimages = $(foreach image,$(multiimages) $(verimages),build/$(image))

# Define the make recipe for all multi images
$(build-multiimages):
	$(eval image = $(subst build/,,$@))
	$(eval variant = $(word 1,$(subst -, ,$(image))))
	$(eval version = $(word 2,$(subst -, ,$(image))))
	$(eval type = $(word 3,$(subst -, ,$(image))))
	$(eval subtype = $(word 4,$(subst -, ,$(image))))
# Construct the folder and legacy tag to use - note that if treats undefined vars as 'false' to avoid extra '-/'
	$(eval folder = $(shell echo $(variant)$(if $(type),/$(type))$(if $(subtype),/$(subtype))))
	$(eval legacytag = $(shell echo $(variant)$(if $(version),:$(version))$(if $(type),-$(type))$(if $(subtype),-$(subtype))))
# Call the generic docker build process
	$(call docker_build,$(image),images/$(folder)/$(if $(version),$(version).)Dockerfile,images/$(folder))
# Populate the cross-reference table
	$(shell echo $(image),$(legacytag) >> build.txt)
#scan created images with Trivy
	$(call scan_image,$(image),)
# Touch an empty file which make itself is using to understand when the image has been last built
	touch $@

base-images-with-versions += $(multiimages)
base-images-with-versions += $(verimages)
s3-images += $(multiimages)

build/php-7.2-fpm build/php-7.3-fpm build/php-7.4-fpm: build/commons
build/php-7.2-cli: build/php-7.2-fpm
build/php-7.3-cli: build/php-7.3-fpm
build/php-7.4-cli: build/php-7.4-fpm
build/php-7.2-cli-drupal: build/php-7.2-cli
build/php-7.3-cli-drupal: build/php-7.3-cli
build/php-7.4-cli-drupal: build/php-7.4-cli
build/python-2.7 build/python-3.7 build/python-3.8 build/python-3.9.0rc1: build/commons
build/python-2.7-ckan: build/python-2.7
build/python-2.7-ckandatapusher: build/python-2.7
build/node-10 build/node-12 build/node-14: build/commons
build/node-10-builder: build/node-10
build/node-12-builder: build/node-12
build/node-14-builder: build/node-14
build/solr-5.5  build/solr-6.6 build/solr-7.7: build/commons
build/solr-5.5-drupal: build/solr-5.5
build/solr-6.6-drupal: build/solr-6.6
build/solr-7.7-drupal: build/solr-7.7
build/solr-5.5-ckan: build/solr-5.5
build/solr-6.6-ckan: build/solr-6.6
build/elasticsearch-6 build/elasticsearch-7 build/kibana-6 build/kibana-7 build/logstash-6 build/logstash-7: build/commons
build/postgres-11 build/postgres-12: build/commons
build/postgres-11-ckan build/postgres-11-drupal: build/postgres-11
build/redis-5 build/redis-6: build/commons
build/redis-5-persistent: build/redis-5
build/redis-5 build/redis-6: build/commons
build/redis-6-persistent: build/redis-6

#######
####### Commands
#######
####### List of commands in our Makefile

# Builds all Images
.PHONY: build
build: $(foreach image,$(base-images) $(base-images-with-versions) ,build/$(image))

# Outputs a list of all Images we manage
.PHONY: build-list
build-list:
	@for number in $(foreach image,$(base-images) $(base-images-with-versions),build/$(image)); do \
			echo $$number ; \
	done

tag-consumer-images = $(foreach image,$(consumer-images),[tag]-$(image))
tag-multiimages = $(foreach image,$(multiimages),[tag]-$(image))
tag-verimages = $(foreach image,$(verimages),[tag]-$(image))

.PHONY: tag-images
tag-images: $(tag-multiimages) $(tag-consumer-images) $(tag-verimages)

.PHONY:
$(tag-multiimages):
	$(eval image = $(subst [tag]-,,$@))
	$(eval variant = $(word 1,$(subst -, ,$(image))))
	$(eval version = $(word 2,$(subst -, ,$(image))))
	$(eval type = $(word 3,$(subst -, ,$(image))))
	$(eval subtype = $(word 4,$(subst -, ,$(image))))
	
	$(eval legacytag = $(shell echo $(variant)$(if $(version),:$(version))$(if $(type),-$(type))$(if $(subtype),-$(subtype))))

	$(info tagging lagoon/$(image):latest as legacy tag lagoon/$(legacytag))
	docker tag lagoon/$(image):latest amazeeio/$(legacytag)

.PHONY:
$(tag-consumer-images):
	$(eval image = $(subst [tag]-,,$@))
	$(info tagging lagoon/$(image):latest)
	docker tag lagoon/$(image):latest amazeeio/$(image):latest

.PHONY:
 $(tag-verimages):
	$(eval image = $(subst [tag]-,,$@))
	$(eval variant = $(word 1,$(subst -, ,$(image))))
	$(eval version = $(word 2,$(subst -, ,$(image))))
	$(eval type = $(word 3,$(subst -, ,$(image))))
	$(eval subtype = $(word 4,$(subst -, ,$(image))))
	
	$(eval legacytag = $(shell echo $(variant)$(if $(type),-$(type))$(if $(subtype),-$(subtype))))

	$(info tagging lagoon/$(image):latest as legacy tag lagoon/$(legacytag))
	docker tag lagoon/$(image):latest amazeeio/$(legacytag)

# Publish command to amazeeio docker hub, this should probably only be done during a master deployments
publish-amazeeio-baseimages = $(foreach image,$(base-images),[publish-amazeeio-baseimages]-$(image))
publish-amazeeio-baseimages-with-versions = $(foreach image,$(base-images-with-versions),[publish-amazeeio-baseimages-with-versions]-$(image))
# tag and push all images
.PHONY: publish-amazeeio-baseimages
publish-amazeeio-baseimages: $(publish-amazeeio-baseimages) $(publish-amazeeio-baseimages-with-versions)


# tag and push of each image
.PHONY: $(publish-amazeeio-baseimages)
$(publish-amazeeio-baseimages):
#   Calling docker_publish for image, but remove the prefix '[publish-amazeeio-baseimages]-' first
		$(eval image = $(subst [publish-amazeeio-baseimages]-,,$@))
# 	Publish images as :latest
		$(call docker_publish_amazeeio,$(image),$(image):latest)
# 	Publish images with version tag
		$(call docker_publish_amazeeio,$(image),$(image):$(LAGOON_VERSION))


# tag and push of base image with version
.PHONY: $(publish-amazeeio-baseimages-with-versions)
$(publish-amazeeio-baseimages-with-versions):
#   Calling docker_publish for image, but remove the prefix '[publish-amazeeio-baseimages-with-versions]-' first
		$(eval image = $(subst [publish-amazeeio-baseimages-with-versions]-,,$@))
#   The underline is a placeholder for a colon, replace that
		$(eval image = $(subst __,:,$(image)))
#		These images already use a tag to differentiate between different versions of the service itself (like node:9 and node:10)
#		We push a version without the `-latest` suffix
		$(call docker_publish_amazeeio,$(image),$(image))
#		Plus a version with the `-latest` suffix, this makes it easier for people with automated testing
		$(call docker_publish_amazeeio,$(image),$(image)-latest)
#		We add the Lagoon Version just as a dash
		$(call docker_publish_amazeeio,$(image),$(image)-$(LAGOON_VERSION))



# Publish command to amazeeio docker hub, this should probably only be done during a master deployments
publish-amazeeiolagoon-baseimages = $(foreach image,$(base-images),[publish-amazeeiolagoon-baseimages]-$(image))
publish-amazeeiolagoon-baseimages-with-versions = $(foreach image,$(base-images-with-versions),[publish-amazeeiolagoon-baseimages-with-versions]-$(image))
# tag and push all images
.PHONY: publish-amazeeiolagoon-baseimages
publish-amazeeiolagoon-baseimages: $(publish-amazeeiolagoon-baseimages) $(publish-amazeeiolagoon-baseimages-with-versions)


# tag and push of each image
.PHONY: $(publish-amazeeiolagoon-baseimages)
$(publish-amazeeiolagoon-baseimages):
#   Calling docker_publish for image, but remove the prefix '[publish-amazeeiolagoon-baseimages]-' first
		$(eval image = $(subst [publish-amazeeiolagoon-baseimages]-,,$@))
# 	Publish images with version tag
		$(call docker_publish_amazeeiolagoon,$(image),$(image):$(BRANCH_NAME))


# tag and push of base image with version
.PHONY: $(publish-amazeeiolagoon-baseimages-with-versions)
$(publish-amazeeiolagoon-baseimages-with-versions):
#   Calling docker_publish for image, but remove the prefix '[publish-amazeeiolagoon-baseimages-with-versions]-' first
		$(eval image = $(subst [publish-amazeeiolagoon-baseimages-with-versions]-,,$@))
#   The underline is a placeholder for a colon, replace that
		$(eval image = $(subst __,:,$(image)))
#		We add the Lagoon Version just as a dash
		$(call docker_publish_amazeeiolagoon,$(image),$(image)-$(BRANCH_NAME))

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
clean:
	rm -rf build/*