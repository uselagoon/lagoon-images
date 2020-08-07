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
CORE_IMAGE_REPO ?= amazeeiolagoon
CORE_IMAGE_TAG ?= v1-8-2

# Local environment
ARCH := $(shell uname | tr '[:upper:]' '[:lower:]')
LAGOON_VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo development)
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

#######
####### Functions
#######

# Builds a docker image. Expects as arguments: name of the image, location of Dockerfile, path of
# Docker Build Context
docker_build = docker build $(DOCKER_BUILD_PARAMS) --build-arg LAGOON_VERSION=$(LAGOON_VERSION) --build-arg IMAGE_REPO=$(CI_BUILD_TAG) --build-arg ALPINE_VERSION=$(DEFAULT_ALPINE_VERSION) -t $(CI_BUILD_TAG)/$(1) -f $(2) $(3)

# Build a Python docker image. Expects as arguments:
# 1. Python version
# 2. Location of Dockerfile
# 3. Path of Docker Build context
docker_build_python = docker build $(DOCKER_BUILD_PARAMS) --build-arg LAGOON_VERSION=$(LAGOON_VERSION) --build-arg IMAGE_REPO=$(CI_BUILD_TAG) --build-arg PYTHON_VERSION=$(1) --build-arg ALPINE_VERSION=$(2) -t $(CI_BUILD_TAG)/python:$(3) -f $(4) $(5)

docker_build_elastic = docker build $(DOCKER_BUILD_PARAMS) --build-arg LAGOON_VERSION=$(LAGOON_VERSION) --build-arg IMAGE_REPO=$(CI_BUILD_TAG) -t $(CI_BUILD_TAG)/$(2):$(1) -f $(3) $(4)

# Build a PHP docker image. Expects as arguments:
# 1. PHP version
# 2. PHP version and type of image (ie 7.3-fpm, 7.3-cli etc)
# 3. Location of Dockerfile
# 4. Path of Docker Build Context
docker_build_php = docker build $(DOCKER_BUILD_PARAMS) --build-arg LAGOON_VERSION=$(LAGOON_VERSION) --build-arg IMAGE_REPO=$(CI_BUILD_TAG) --build-arg PHP_VERSION=$(1)  --build-arg PHP_IMAGE_VERSION=$(1) --build-arg ALPINE_VERSION=$(2) -t $(CI_BUILD_TAG)/php:$(3) -f $(4) $(5)

docker_build_node = docker build $(DOCKER_BUILD_PARAMS) --build-arg LAGOON_VERSION=$(LAGOON_VERSION) --build-arg IMAGE_REPO=$(CI_BUILD_TAG) --build-arg NODE_VERSION=$(1) --build-arg ALPINE_VERSION=$(2) -t $(CI_BUILD_TAG)/node:$(3) -f $(4) $(5)

docker_build_solr = docker build $(DOCKER_BUILD_PARAMS) --build-arg LAGOON_VERSION=$(LAGOON_VERSION) --build-arg IMAGE_REPO=$(CI_BUILD_TAG) --build-arg SOLR_MAJ_MIN_VERSION=$(1) -t $(CI_BUILD_TAG)/solr:$(2) -f $(3) $(4)

# Tags an image with the `amazeeio` repository and pushes it
docker_publish_amazeeio = docker tag $(CI_BUILD_TAG)/$(1) amazeeio/$(2) && docker push amazeeio/$(2) | cat

# Tags an image with the `amazeeiolagoon` repository and pushes it
docker_publish_amazeeiolagoon = docker tag $(CI_BUILD_TAG)/$(1) amazeeiolagoon/$(2) && docker push amazeeiolagoon/$(2) | cat

#######
####### Base Images
#######
####### Base Images are the base for all other images and are also published for clients to use during local development

deploy-images := kubectl-build-deploy-dind \
							docker-host

consumer-images :=     commons \
							mariadb \
							mariadb-drupal \
							mongo \
							nginx \
							nginx-drupal \
							postgres \
							postgres-ckan \
							postgres-drupal \
							redis \
							redis-persistent \
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
build/postgres: build/commons images/postgres/Dockerfile
build/postgres-ckan: build/postgres images/postgres-ckan/Dockerfile
build/postgres-drupal: build/postgres images/postgres-drupal/Dockerfile
build/redis: build/commons images/redis/Dockerfile
build/redis-persistent: build/redis images/redis-persistent/Dockerfile
build/varnish: build/commons images/varnish/Dockerfile
build/varnish-drupal: build/varnish images/varnish-drupal/Dockerfile
build/varnish-persistent: build/varnish images/varnish/Dockerfile
build/varnish-persistent-drupal: build/varnish-persistent images/varnish-drupal/Dockerfile
build/docker-host: build/commons images/docker-host/Dockerfile
build/athenapdf-service: build/commons images/athenapdf-service/Dockerfile
build/toolbox: build/commons images/toolbox/Dockerfile
build/kubectl-build-deploy-dind: build/kubectl images/kubectl-build-deploy-dind

#######
####### Elastic Images
#######

elasticimages :=  elasticsearch__6 \
								  elasticsearch__7 \
									kibana__6 \
									kibana__7 \
									logstash__6 \
									logstash__7

build-elasticimages = $(foreach image,$(elasticimages),build/$(image))

# Define the make recipe for all base images
$(build-elasticimages): build/commons
	$(eval clean = $(subst build/,,$@))
	$(eval tool = $(word 1,$(subst __, ,$(clean))))
	$(eval version = $(word 2,$(subst __, ,$(clean))))
# Call the docker build
	$(call docker_build_elastic,$(version),$(tool),images/$(tool)/Dockerfile$(version),images/$(tool))
# Touch an empty file which make itself is using to understand when the image has been last build
	touch $@

base-images-with-versions += $(elasticimages)
s3-images += $(elasticimages)

build/elasticsearch__6 build/elasticsearch__7 build/kibana__6 build/kibana__7 build/logstash__6 build/logstash__7: images/commons

#######
####### Python Images
#######
####### Python Images are alpine linux based Python images.

pythonimages :=  python__2.7 \
								 python__3.7 \
								 python__2.7-ckan \
								 python__2.7-ckandatapusher

build-pythonimages = $(foreach image,$(pythonimages),build/$(image))

# Define the make recipe for all base images
$(build-pythonimages): build/commons
	$(eval clean = $(subst build/python__,,$@))
	$(eval version = $(word 1,$(subst -, ,$(clean))))
	$(eval type = $(word 2,$(subst -, ,$(clean))))
	$(eval alpine_version := $(shell case $(version) in (2.7|3.7) echo "3.10" ;; (*) echo $(DEFAULT_ALPINE_VERSION) ;; esac ))
# this fills variables only if $type is existing, if not they are just empty
	$(eval type_dash = $(if $(type),-$(type)))
# Call the docker build
	$(call docker_build_python,$(version),$(alpine_version),$(version)$(type_dash),images/python$(type_dash)/Dockerfile,images/python$(type_dash))
# Touch an empty file which make itself is using to understand when the image has been last build
	touch $@

base-images-with-versions += $(pythonimages)
s3-images += $(pythonimages)

build/python__2.7 build/python__3.7: images/commons
build/python__2.7-ckan: build/python__2.7
build/python__2.7-ckandatapusher: build/python__2.7


#######
####### PHP Images
#######
####### PHP Images are alpine linux based PHP images.

phpimages := 	php__7.2-fpm \
				php__7.3-fpm \
				php__7.4-fpm \
				php__7.2-cli \
				php__7.3-cli \
				php__7.4-cli \
				php__7.2-cli-drupal \
				php__7.3-cli-drupal \
				php__7.4-cli-drupal


build-phpimages = $(foreach image,$(phpimages),build/$(image))

# Define the make recipe for all base images
$(build-phpimages): build/commons
	$(eval clean = $(subst build/php__,,$@))
	$(eval version = $(word 1,$(subst -, ,$(clean))))
	$(eval type = $(word 2,$(subst -, ,$(clean))))
	$(eval subtype = $(word 3,$(subst -, ,$(clean))))
	$(eval alpine_version := $(shell case $(version) in (5.6) echo "3.8" ;; (7.0) echo "3.7" ;; (7.1) echo "3.10" ;; (*) echo $(DEFAULT_ALPINE_VERSION) ;; esac ))
# this fills variables only if $type is existing, if not they are just empty
	$(eval type_dash = $(if $(type),-$(type)))
	$(eval type_slash = $(if $(type),/$(type)))
# if there is a subtype, add it. If not, just keep what we already had
	$(eval type_dash = $(if $(subtype),-$(type)-$(subtype),$(type_dash)))
	$(eval type_slash = $(if $(subtype),/$(type)-$(subtype),$(type_slash)))

# Call the docker build
	$(call docker_build_php,$(version),$(alpine_version),$(version)$(type_dash),images/php$(type_slash)/Dockerfile,images/php$(type_slash))
# Touch an empty file which make itself is using to understand when the image has been last build
	touch $@

base-images-with-versions += $(phpimages)
s3-images += $(phpimages)

build/php__7.2-fpm build/php__7.3-fpm build/php__7.4-fpm: images/commons
build/php__7.2-cli: build/php__7.2-fpm
build/php__7.3-cli: build/php__7.3-fpm
build/php__7.4-cli: build/php__7.4-fpm
build/php__7.2-cli-drupal: build/php__7.2-cli
build/php__7.3-cli-drupal: build/php__7.3-cli
build/php__7.4-cli-drupal: build/php__7.4-cli

#######
####### Solr Images
#######
####### Solr Images are alpine linux based Solr images.

solrimages := 	solr__5.5 \
				solr__6.6 \
				solr__7.7 \
				solr__5.5-drupal \
				solr__6.6-drupal \
				solr__7.7-drupal \
				solr__5.5-ckan \
				solr__6.6-ckan


build-solrimages = $(foreach image,$(solrimages),build/$(image))

# Define the make recipe for all base images
$(build-solrimages): build/commons
	$(eval clean = $(subst build/solr__,,$@))
	$(eval version = $(word 1,$(subst -, ,$(clean))))
	$(eval type = $(word 2,$(subst -, ,$(clean))))
# this fills variables only if $type is existing, if not they are just empty
	$(eval type_dash = $(if $(type),-$(type)))
# Call the docker build
	$(call docker_build_solr,$(version),$(version)$(type_dash),images/solr$(type_dash)/Dockerfile,images/solr$(type_dash))
# Touch an empty file which make itself is using to understand when the image has been last build
	touch $@

base-images-with-versions += $(solrimages)
s3-images += $(solrimages)

build/solr__5.5  build/solr__6.6 build/solr__7.7: images/commons
build/solr__5.5-drupal: build/solr__5.5
build/solr__6.6-drupal: build/solr__6.6
build/solr__7.7-drupal: build/solr__7.7
build/solr__5.5-ckan: build/solr__5.5
build/solr__6.6-ckan: build/solr__6.6

#######
####### Node Images
#######
####### Node Images are alpine linux based Node images.

nodeimages := 	node__14 \
				node__12 \
				node__10 \
				node__14-builder \
				node__12-builder \
				node__10-builder \

build-nodeimages = $(foreach image,$(nodeimages),build/$(image))

# Define the make recipe for all base images
$(build-nodeimages): build/commons
	$(eval clean = $(subst build/node__,,$@))
	$(eval version = $(word 1,$(subst -, ,$(clean))))
	$(eval type = $(word 2,$(subst -, ,$(clean))))
	$(eval alpine_version := $(shell case $(version) in (6) echo "" ;; (9) echo "" ;; (*) echo $(DEFAULT_ALPINE_VERSION) ;; esac ))
# this fills variables only if $type is existing, if not they are just empty
	$(eval type_dash = $(if $(type),-$(type)))
	$(eval type_slash = $(if $(type),/$(type)))
# Call the docker build
	$(call docker_build_node,$(version),$(alpine_version),$(version)$(type_dash),images/node$(type_slash)/Dockerfile,images/node$(type_slash))
# Touch an empty file which make itself is using to understand when the image has been last build
	touch $@

base-images-with-versions += $(nodeimages)
s3-images += $(nodeimages)

build/node__10 build/node__12 build/node__14: images/commons images/node/Dockerfile
build/node__14-builder: build/node__14 images/node/builder/Dockerfile
build/node__12-builder: build/node__12 images/node/builder/Dockerfile
build/node__10-builder: build/node__10 images/node/builder/Dockerfile

# Images for local helpers that exist in another folder than the service images
localdevimages := local-git \
									local-api-data-watcher-pusher \
									local-registry\
									local-dbaas-provider
build-localdevimages = $(foreach image,$(localdevimages),build/$(image))

$(build-localdevimages):
	$(eval folder = $(subst build/local-,,$@))
	$(eval image = $(subst build/,,$@))
	$(call docker_build,$(image),local-dev/$(folder)/Dockerfile,local-dev/$(folder))
	touch $@

# Image with ansible test
build/tests:
	$(eval image = $(subst build/,,$@))
	$(call docker_build,$(image),$(image)/Dockerfile,$(image))
	touch $@

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
	@for number in $(foreach image,$(build-images),build/$(image)); do \
			echo $$number ; \
	done

# Define list of all tests
all-k8s-tests-list:= features-kubernetes \
									nginx \
									drupal \
									active-standby-kubernetes
all-k8s-tests = $(foreach image,$(all-k8s-tests-list),k8s-tests/$(image))

# Run all k8s tests
.PHONY: k8s-tests
k8s-tests: $(all-k8s-tests)

.PHONY: $(all-k8s-tests)
$(all-k8s-tests): k3d up
		$(MAKE) push-local-registry -j6
		$(eval testname = $(subst k8s-tests/,,$@))
		IMAGE_REPO=$(CORE_IMAGE_REPO) IMAGE_TAG=$(CORE_IMAGE_TAG) docker-compose -p $(CI_BUILD_TAG) --compatibility run --rm \
			tests-kubernetes ansible-playbook --skip-tags="skip-on-kubernetes" \
			/ansible/tests/$(testname).yaml \
			--extra-vars \
			"$$(cat $$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)') | \
				jq -rcsR '{kubeconfig: .}')"

# push command of our base images
push-local-registry-images = $(foreach image,$(base-images) $(base-images-with-versions),[push-local-registry]-$(image))
# tag and push all images
.PHONY: push-local-registry
push-local-registry: $(push-local-registry-images)
# tag and push of each image
.PHONY:
	docker login -u admin -p admin 172.17.0.1:8084
	$(push-local-registry-images)

$(push-local-registry-images):
	$(eval image = $(subst [push-local-registry]-,,$@))
	$(eval image = $(subst __,:,$(image)))
	$(info pushing $(image) to local local-registry)
	if docker inspect $(BASE_IMAGE_REPO)/$(image) > /dev/null 2>&1; then \
		docker tag $(BASE_IMAGE_REPO)/$(image) localhost:5000/lagoon/$(image) && \
		docker push localhost:5000/lagoon/$(image) | cat; \
	fi

# Run all tests
.PHONY: tests
tests: k8s-tests

# Wait for Keycloak to be ready (before this no API calls will work)
.PHONY: wait-for-keycloak
wait-for-keycloak:
	$(info Waiting for Keycloak to be ready....)
	grep -m 1 "Config of Keycloak done." <(docker-compose -p $(CI_BUILD_TAG) --compatibility logs -f keycloak 2>&1)

.PHONY: local-registry-up
local-registry-up: build/local-registry
	IMAGE_REPO=$(CORE_IMAGE_REPO) IMAGE_TAG=$(CORE_IMAGE_TAG) docker-compose -p $(CI_BUILD_TAG) --compatibility up -d local-registry

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

# Show Lagoon Service Logs
logs:
	IMAGE_REPO=$(CI_BUILD_TAG) docker-compose -p $(CI_BUILD_TAG) --compatibility logs --tail=10 -f $(service)

# Start all Lagoon Services
up:
	IMAGE_REPO=$(CORE_IMAGE_REPO) IMAGE_TAG=$(CORE_IMAGE_TAG) docker-compose -p $(CI_BUILD_TAG) pull --include-deps
ifeq ($(ARCH), darwin)
	IMAGE_REPO=$(CORE_IMAGE_REPO) IMAGE_TAG=$(CORE_IMAGE_TAG) docker-compose -p $(CI_BUILD_TAG) --compatibility up -d
else
	# once this docker issue is fixed we may be able to do away with this
	# linux-specific workaround: https://github.com/docker/cli/issues/2290
	KEYCLOAK_URL=$$(docker network inspect -f '{{(index .IPAM.Config 0).Gateway}}' bridge):8088 \
		IMAGE_REPO=$(CORE_IMAGE_REPO) IMAGE_TAG=$(CORE_IMAGE_TAG) \
		docker-compose -p $(CI_BUILD_TAG) --compatibility up -d
endif
	grep -m 1 ".opendistro_security index does not exist yet" <(docker-compose -p $(CI_BUILD_TAG) logs -f logs-db 2>&1)
	while ! docker exec "$$(docker-compose -p $(CI_BUILD_TAG) ps -q logs-db)" ./securityadmin_demo.sh; do sleep 5; done
	$(MAKE) wait-for-keycloak

down:
	IMAGE_REPO=$(CORE_IMAGE_REPO) IMAGE_TAG=$(CORE_IMAGE_TAG) docker-compose -p $(CI_BUILD_TAG) --compatibility down -v --remove-orphans

# kill all containers containing the name "lagoon"
kill:
	docker ps --format "{{.Names}}" | grep lagoon | xargs -t -r -n1 docker rm -f -v

# Symlink the installed k3d client if the correct version is already
# installed, otherwise downloads it.
local-dev/k3d:
ifeq ($(K3D_VERSION), $(shell k3d version 2>/dev/null | grep k3d | sed -E 's/^k3d version v([0-9.]+).*/\1/'))
	$(info linking local k3d version $(K3D_VERSION))
	ln -s $(shell command -v k3d) ./local-dev/k3d
else
	$(info downloading k3d version $(K3D_VERSION) for $(ARCH))
	curl -Lo local-dev/k3d https://github.com/rancher/k3d/releases/download/v$(K3D_VERSION)/k3d-$(ARCH)-amd64
	chmod a+x local-dev/k3d
endif

# Symlink the installed kubectl client if the correct version is already
# installed, otherwise downloads it.
local-dev/kubectl:
ifeq ($(KUBECTL_VERSION), $(shell kubectl version --short --client 2>/dev/null | sed -E 's/Client Version: v([0-9.]+).*/\1/'))
	$(info linking local kubectl version $(KUBECTL_VERSION))
	ln -s $(shell command -v kubectl) ./local-dev/kubectl
else
	$(info downloading kubectl version $(KUBECTL_VERSION) for $(ARCH))
	curl -Lo local-dev/kubectl https://storage.googleapis.com/kubernetes-release/release/$(KUBECTL_VERSION)/bin/$(ARCH)/amd64/kubectl
	chmod a+x local-dev/kubectl
endif

# Symlink the installed helm client if the correct version is already
# installed, otherwise downloads it.
local-dev/helm/helm:
	@mkdir -p ./local-dev/helm
ifeq ($(HELM_VERSION), $(shell helm version --short --client 2>/dev/null | sed -E 's/v([0-9.]+).*/\1/'))
	$(info linking local helm version $(HELM_VERSION))
	ln -s $(shell command -v helm) ./local-dev/helm
else
	$(info downloading helm version $(HELM_VERSION) for $(ARCH))
	curl -L https://get.helm.sh/helm-$(HELM_VERSION)-$(ARCH)-amd64.tar.gz | tar xzC local-dev/helm --strip-components=1
	chmod a+x local-dev/helm/helm
endif

ifeq ($(DOCKER_DRIVER), btrfs)
# https://github.com/rancher/k3d/blob/master/docs/faq.md
K3D_BTRFS_VOLUME := --volume /dev/mapper:/dev/mapper
else
K3D_BTRFS_VOLUME :=
endif

k3d: local-dev/k3d local-dev/kubectl local-dev/helm/helm
	$(MAKE) local-registry-up
	$(info starting k3d with name $(K3D_NAME))
	$(info Creating Loopback Interface for docker gateway if it does not exist, this might ask for sudo)
ifeq ($(ARCH), darwin)
	if ! ifconfig lo0 | grep $$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}') -q; then sudo ifconfig lo0 alias $$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}'); fi
endif
	./local-dev/k3d create --wait 0 --publish 18080:80 \
		--publish 18443:443 \
		--api-port 16643 \
		--name $(K3D_NAME) \
		--image docker.io/rancher/k3s:$(K3S_VERSION) \
		--volume $$PWD/local-dev/k3d-registries.yaml:/etc/rancher/k3s/registries.yaml \
		$(K3D_BTRFS_VOLUME) \
		-x --no-deploy=traefik \
		--volume $$PWD/local-dev/k3d-nginx-ingress.yaml:/var/lib/rancher/k3s/server/manifests/k3d-nginx-ingress.yaml
	echo "$(K3D_NAME)" > $@
	export KUBECONFIG="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')"; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" apply -f $$PWD/local-dev/k3d-storageclass-bulk.yaml; \
	$(MAKE) push-docker-host
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' create namespace k8up; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' repo add appuio https://charts.appuio.ch; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' upgrade --install -n k8up k8up appuio/k8up; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' create namespace dioscuri; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' repo add dioscuri https://raw.githubusercontent.com/amazeeio/dioscuri/ingress/charts ; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' upgrade --install -n dioscuri dioscuri dioscuri/dioscuri ; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' create namespace dbaas-operator; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' repo add dbaas-operator https://raw.githubusercontent.com/amazeeio/dbaas-operator/master/charts ; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' upgrade --install -n dbaas-operator dbaas-operator dbaas-operator/dbaas-operator ; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' upgrade --install -n dbaas-operator mariadbprovider dbaas-operator/mariadbprovider -f local-dev/helm-values-mariadbprovider.yml ; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' create namespace lagoon; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' repo add amazeeio https://amazeeio.github.io/charts/; \
	local-dev/helm/helm --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --kube-context='$(K3D_NAME)' upgrade --install -n lagoon lagoon-remote amazeeio/lagoon-remote --set dockerHost.image.name=172.17.0.1:5000/lagoon/docker-host --set dockerHost.registry=172.17.0.1:5000; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n lagoon rollout status deployment docker-host -w;
ifeq ($(ARCH), darwin)
	export KUBECONFIG="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')"; \
	KUBERNETESBUILDDEPLOY_TOKEN=$$(local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n lagoon describe secret $$(local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n lagoon get secret | grep kubernetesbuilddeploy | awk '{print $$1}') | grep token: | awk '{print $$2}'); \
	sed -i '' -e "s/\".*\" # make-kubernetes-token/\"$${KUBERNETESBUILDDEPLOY_TOKEN}\" # make-kubernetes-token/g" local-dev/api-data/03-populate-api-data-kubernetes.gql; \
	DOCKER_IP="$$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')"; \
	sed -i '' -e "s/172\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$${DOCKER_IP}/g" local-dev/api-data/03-populate-api-data-kubernetes.gql docker-compose.yaml;
else
	export KUBECONFIG="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')"; \
	KUBERNETESBUILDDEPLOY_TOKEN=$$(local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n lagoon describe secret $$(local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n lagoon get secret | grep kubernetesbuilddeploy | awk '{print $$1}') | grep token: | awk '{print $$2}'); \
	sed -i "s/\".*\" # make-kubernetes-token/\"$${KUBERNETESBUILDDEPLOY_TOKEN}\" # make-kubernetes-token/g" local-dev/api-data/03-populate-api-data-kubernetes.gql; \
	DOCKER_IP="$$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')"; \
	sed -i "s/172\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$${DOCKER_IP}/g" local-dev/api-data/03-populate-api-data-kubernetes.gql docker-compose.yaml;
endif
	$(MAKE) push-kubectl-build-deploy-dind

.PHONY: push-docker-host
push-docker-host:
	docker pull $(CORE_IMAGE_REPO)/docker-host:${CORE_IMAGE_TAG}
	docker tag $(CORE_IMAGE_REPO)/docker-host:${CORE_IMAGE_TAG} localhost:5000/lagoon/docker-host
	docker push localhost:5000/lagoon/docker-host

.PHONY: push-kubectl-build-deploy-dind
push-kubectl-build-deploy-dind:
	docker pull $(CORE_IMAGE_REPO)/kubectl-build-deploy-dind:${CORE_IMAGE_TAG}
	docker tag $(CORE_IMAGE_REPO)/kubectl-build-deploy-dind:${CORE_IMAGE_TAG} localhost:5000/lagoon/kubectl-build-deploy-dind
	docker push localhost:5000/lagoon/kubectl-build-deploy-dind

.PHONY: rebuild-push-kubectl-build-deploy-dind
rebuild-push-kubectl-build-deploy-dind:
	rm -rf build/kubectl-build-deploy-dind
	$(MAKE) push-kubectl-build-deploy-dind

k3d-kubeconfig:
	export KUBECONFIG="$$(./local-dev/k3d get-kubeconfig --name=$$(cat k3d))"

k3d-dashboard:
	export KUBECONFIG="$$(./local-dev/k3d get-kubeconfig --name=$$(cat k3d))"; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/00_dashboard-namespace.yaml; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/01_dashboard-serviceaccount.yaml; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/02_dashboard-service.yaml; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/03_dashboard-secret.yaml; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/04_dashboard-configmap.yaml; \
	echo '{"apiVersion": "rbac.authorization.k8s.io/v1","kind": "ClusterRoleBinding","metadata": {"name": "kubernetes-dashboard","namespace": "kubernetes-dashboard"},"roleRef": {"apiGroup": "rbac.authorization.k8s.io","kind": "ClusterRole","name": "cluster-admin"},"subjects": [{"kind": "ServiceAccount","name": "kubernetes-dashboard","namespace": "kubernetes-dashboard"}]}' | local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n kubernetes-dashboard apply -f - ; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/06_dashboard-deployment.yaml; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/07_scraper-service.yaml; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended/08_scraper-deployment.yaml; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n kubernetes-dashboard patch deployment kubernetes-dashboard --patch '{"spec": {"template": {"spec": {"containers": [{"name": "kubernetes-dashboard","args": ["--auto-generate-certificates","--namespace=kubernetes-dashboard","--enable-skip-login"]}]}}}}'; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n kubernetes-dashboard rollout status deployment kubernetes-dashboard -w; \
	open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ ; \
	local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' proxy

k8s-dashboard:
	kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml; \
	kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n kubernetes-dashboard rollout status deployment kubernetes-dashboard -w; \
	echo -e "\nUse this token:"; \
	kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n lagoon describe secret $$(local-dev/kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' -n lagoon get secret | grep kubernetesbuilddeploy | awk '{print $$1}') | grep token: | awk '{print $$2}'; \
	open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ ; \
	kubectl --kubeconfig="$$(./local-dev/k3d get-kubeconfig --name='$(K3D_NAME)')" --context='$(K3D_NAME)' proxy

# Stop k3d
.PHONY: k3d/stop
k3d/stop: local-dev/k3d
	./local-dev/k3d delete --name=$$(cat k3d) || true
	rm -f k3d

# Stop All k3d
.PHONY: k3d/stopall
k3d/stopall: local-dev/k3d
	./local-dev/k3d delete --all || true
	rm -f k3d

# Stop k3d, remove downloaded k3d
.PHONY: k3d/clean
k3d/clean: k3d/stop
	rm -rf ./local-dev/k3d

# Stop All k3d, remove downloaded k3d
.PHONY: k3d/cleanall
k3d/cleanall: k3d/stopall
	rm -rf ./local-dev/k3d

# Configures Kubernetes to use with Lagoon
.PHONY: kubernetes-lagoon-setup
kubernetes-lagoon-setup:
	kubectl create namespace lagoon; \
	local-dev/helm/helm upgrade --install -n lagoon lagoon-remote ./charts/lagoon-remote; \
	echo -e "\n\nAll Setup, use this token as described in the Lagoon Install Documentation:";
	$(MAKE) kubernetes-get-kubernetesbuilddeploy-token

.PHONY: kubernetes-get-kubernetesbuilddeploy-token
kubernetes-get-kubernetesbuilddeploy-token:
	kubectl -n lagoon describe secret $$(kubectl -n lagoon get secret | grep kubernetesbuilddeploy | awk '{print $$1}') | grep token: | awk '{print $$2}'
