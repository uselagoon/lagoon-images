# docker-bake.dev.hcl
variable "IMAGE_REPO" {
  default = "ghcr.io/uselagoon"
}

variable "TAG" {
  default = "latest"
}

variable "LAGOON_VERSION" {
  default = "development"
}

variable "UPSTREAM_REPO" {
  default = "uselagoon"
}

variable "UPSTREAM_TAG" {
  default = "latest"
}

variable "PLATFORMS" {
  // use PLATFORMS=linux/amd64,linux/arm64 to override default single architecture on the cli
  default = "linux/amd64"
}

target "default"{
  platforms = ["${PLATFORMS}"]
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.authors": "The Lagoon Authors",
    "org.opencontainers.image.url": "https://github.com/uselagoon/lagoon-images",
    "org.opencontainers.image.licenses": "Apache-2.0",
    "org.opencontainers.image.version": "${LAGOON_VERSION}",
    "repository": "https://github.com/uselagoon/lagoon-images"
  }
  args = {
    LAGOON_VERSION = "${LAGOON_VERSION}"
    UPSTREAM_REPO = "${UPSTREAM_REPO}"
    UPSTREAM_TAG = "${UPSTREAM_TAG}"
  }
}

group "default" {
  targets = [
    "commons", 
    "mariadb-10-4",
    "mariadb-10-4-drupal",
    "mariadb-10-5",
    "mariadb-10-5-drupal",
    "mariadb-10-6",
    "mariadb-10-6-drupal",
    "mariadb-10-11",
    "mariadb-10-11-drupal",
    "mongo-4",
    "mysql-8-0",
    "mysql-8-4",
    "nginx",
    "nginx-drupal",
    "node-18",
    "node-18-builder",
    "node-18-cli",
    "node-20",
    "node-20-builder",
    "node-20-cli",
    "node-22",
    "node-22-builder",
    "node-22-cli",
    "opensearch-2",
    "php-8-1-fpm",
    "php-8-1-cli",
    "php-8-1-cli-drupal",
    "php-8-2-fpm",
    "php-8-2-cli",
    "php-8-2-cli-drupal",
    "php-8-3-fpm",
    "php-8-3-cli",
    "php-8-3-cli-drupal",
    "postgres-11",
    "postgres-11-drupal",
    "postgres-12",
    "postgres-12-drupal",
    "postgres-13",
    "postgres-13-drupal",
    "postgres-14",
    "postgres-14-drupal",
    "postgres-15",
    "postgres-15-drupal",
    "postgres-16",
    "postgres-16-drupal",
    "python-3-8",
    "python-3-9",
    "python-3-10",
    "python-3-11",
    "python-3-12",
    "rabbitmq",
    "redis-6",
    "redis-6-persistent",
    "redis-7",
    "redis-7-persistent",
    "ruby-3-1",
    "ruby-3-2",
    "ruby-3-3",
    "solr-8",
    "solr-8-drupal",
    "solr-9",
    "solr-9-drupal",
    "varnish-6",
    "varnish-6-drupal",
    "varnish-6-persistent",
    "varnish-6-persistent-drupal",
    "varnish-7",
    "varnish-7-drupal",
    "varnish-7-persistent",
    "varnish-7-persistent-drupal"
  ]
}

group "mariadb" {
  targets = [
    "commons", 
    "mariadb-10-4",
    "mariadb-10-4-drupal",
    "mariadb-10-5",
    "mariadb-10-5-drupal",
    "mariadb-10-6",
    "mariadb-10-6-drupal",
    "mariadb-10-11",
    "mariadb-10-11-drupal"
  ]
}

group "mysql" {
  targets = [
    "commons", 
    "mysql-8-0",
    "mysql-8-4"
  ]
}

group "node" {
  targets = [
    "commons", 
    "node-18",
    "node-18-builder",
    "node-18-cli",
    "node-20",
    "node-20-builder",
    "node-20-cli",
    "node-22",
    "node-22-builder",
    "node-22-cli"
  ]
}

group "php" {
  targets = [
    "commons", 
    "php-8-1-fpm",
    "php-8-1-cli",
    "php-8-1-cli-drupal",
    "php-8-2-fpm",
    "php-8-2-cli",
    "php-8-2-cli-drupal",
    "php-8-3-fpm",
    "php-8-3-cli",
    "php-8-3-cli-drupal"
  ]
}

group "postgres" {
  targets = [
    "commons", 
    "postgres-11",
    "postgres-11-drupal",
    "postgres-12",
    "postgres-12-drupal",
    "postgres-13",
    "postgres-13-drupal",
    "postgres-14",
    "postgres-14-drupal",
    "postgres-15",
    "postgres-15-drupal",
    "postgres-16",
    "postgres-16-drupal"
  ]
}

group "python" {
  targets = [
    "commons", 
    "python-3-8",
    "python-3-9",
    "python-3-10",
    "python-3-11",
    "python-3-12"
  ]
}

group "redis" {
  targets = [
    "commons", 
    "redis-6",
    "redis-6-persistent",
    "redis-7",
    "redis-7-persistent"
  ]
}

group "ruby" {
  targets = [
    "commons", 
    "ruby-3-1",
    "ruby-3-2",
    "ruby-3-3"
  ]
}

group "solr" {
  targets = [
    "commons", 
    "solr-8",
    "solr-8-drupal",
    "solr-9",
    "solr-9-drupal"
  ]
}

group "varnish" {
  targets = [
    "commons", 
    "varnish-6",
    "varnish-6-drupal",
    "varnish-6-persistent",
    "varnish-6-persistent-drupal",
    "varnish-7",
    "varnish-7-drupal",
    "varnish-7-persistent",
    "varnish-7-persistent-drupal"
  ]
}

group "others" {
  targets =[
    "commons",
    "mongo-4",
    "nginx",
    "nginx-drupal",
    "opensearch-2",
    "rabbitmq"
  ]
}

target "commons" {
  inherits = ["default"]
  context = "images/commons"
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/commons/Dockerfile",
    "org.opencontainers.image.description": "Base image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/commons",
    "org.opencontainers.image.base.name": "docker.io/alpine:3.19"
  }
  tags = ["${IMAGE_REPO}/commons:${TAG}"]
}

target "mariadb-10-4" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.4.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mariadb/10.4.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.4 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.4",
    "org.opencontainers.image.base.name": "docker.io/alpine:3.12"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.4:${TAG}"]
}

target "mariadb-10-4-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.4": "target:mariadb-10-4"
  }
  dockerfile = "10.4.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mariadb-drupal/10.4.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.4 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.4-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/mariadb-10.4"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.4-drupal:${TAG}"]
}

target "mariadb-10-5" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.5.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mariadb/10.5.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.5 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.5",
    "org.opencontainers.image.base.name": "docker.io/alpine:3.14"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.5:${TAG}"]
}

target "mariadb-10-5-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.5": "target:mariadb-10-5"
  }
  dockerfile = "10.5.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mariadb-drupal/10.5.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.5 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.5-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/mariadb-10.5"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.5-drupal:${TAG}"]
}

target "mariadb-10-6" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mariadb/10.6.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.6 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.6",
    "org.opencontainers.image.base.name": "docker.io/alpine:3.17"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.6:${TAG}"]
}

target "mariadb-10-6-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.6": "target:mariadb-10-6"
  }
  dockerfile = "10.6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mariadb-drupal/10.6.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.6 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.6-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/mariadb-10.6"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.6-drupal:${TAG}"]
}

target "mariadb-10-11" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.11.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/main/images/mariadb/10.11.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.11 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.11",
    "org.opencontainers.image.base.name": "docker.io/alpine:3.19"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.11:${TAG}"]
}

target "mariadb-10-11-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.11": "target:mariadb-10-11"
  }
  dockerfile = "10.11.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mariadb-drupal/10.11.Dockerfile",
    "org.opencontainers.image.description": "MariaDB 10.11 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mariadb-10.11-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/mariadb-10.11"
  }
  tags = ["${IMAGE_REPO}/mariadb-10.11-drupal:${TAG}"]
}

target "mongo-4" {
  inherits = ["default"]
  context = "images/mongo"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "4.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mongo/4.Dockerfile",
    "org.opencontainers.image.description": "MongoDB 4 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mongo-4",
    "org.opencontainers.image.base.name": "docker.io/alpine:3.19"
  }
  tags = ["${IMAGE_REPO}/mongo-4:${TAG}"]
}

target "mysql-8-0" {
  inherits = ["default"]
  context = "images/mysql"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.0.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mysql/8.0.Dockerfile",
    "org.opencontainers.image.description": "MySQL 8.0 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mysql-8.0",
    "org.opencontainers.image.base.name": "docker.io/mysql:8.0-oracle"
  }
  tags = ["${IMAGE_REPO}/mysql-8.0:${TAG}"]
}

target "mysql-8-4" {
  inherits = ["default"]
  context = "images/mysql"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.4.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/mysql/8.4.Dockerfile",
    "org.opencontainers.image.description": "MySQL 8.4 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/mysql-8.4",
    "org.opencontainers.image.base.name": "docker.io/mysql:8.4-oracle"
  }
  tags = ["${IMAGE_REPO}/mysql-8.4:${TAG}"]
}

target "nginx" {
  inherits = ["default"]
  context = "images/nginx"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/nginx/Dockerfile",
    "org.opencontainers.image.description": "OpenResty (Nginx) image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/nginx",
    "org.opencontainers.image.base.name": "docker.io/openresty/openresty:1.25-alpine"
  }
  tags = ["${IMAGE_REPO}/nginx:${TAG}"]
}

target "nginx-drupal" {
  inherits = ["default"]
  context = "images/nginx-drupal"
  contexts = {
    "lagoon/nginx": "target:nginx"
  }
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/nginx-drupal/Dockerfile",
    "org.opencontainers.image.description": "OpenResty (Nginx) image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/nginx-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/nginx"
  }
  tags = ["${IMAGE_REPO}/nginx-drupal:${TAG}"]
}

target "node-18" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "18.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node/18.Dockerfile",
    "org.opencontainers.image.description": "Node.js 18 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-18",
    "org.opencontainers.image.base.name": "docker.io/node:18-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/node-18:${TAG}"]
}

target "node-18-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-18": "target:node-18"
  }
  dockerfile = "18.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node-builder/18.Dockerfile",
    "org.opencontainers.image.description": "Node.js 18 builder image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-18-builder",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/node-18"
  }
  tags = ["${IMAGE_REPO}/node-18-builder:${TAG}"]
}

target "node-18-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-18": "target:node-18"
  }
  dockerfile = "18.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node-cli/18.Dockerfile",
    "org.opencontainers.image.description": "Node.js 18 CLI image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-18-cli",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/node-18"
  }
  tags = ["${IMAGE_REPO}/node-18-cli:${TAG}"]
}

target "node-20" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "20.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node/20.Dockerfile",
    "org.opencontainers.image.description": "Node.js 20 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-20",
    "org.opencontainers.image.base.name": "docker.io/node:20-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/node-20:${TAG}"]
}

target "node-20-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node-builder/20.Dockerfile",
    "org.opencontainers.image.description": "Node.js 20 builder image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-20-builder",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/node-20"
  }
  tags = ["${IMAGE_REPO}/node-20-builder:${TAG}"]
}

target "node-20-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node-cli/20.Dockerfile",
    "org.opencontainers.image.description": "Node.js 20 CLI image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-20-cli",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/node-20"
  }
  tags = ["${IMAGE_REPO}/node-20-cli:${TAG}"]
}

target "node-22" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "22.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node/22.Dockerfile",
    "org.opencontainers.image.description": "Node.js 22 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-22",
    "org.opencontainers.image.base.name": "docker.io/node:22-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/node-22:${TAG}"]
}

target "node-22-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-22": "target:node-22"
  }
  dockerfile = "22.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node-builder/22.Dockerfile",
    "org.opencontainers.image.description": "Node.js 22 builder image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-22-builder",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/node-22"
  }
  tags = ["${IMAGE_REPO}/node-22-builder:${TAG}"]
}

target "node-22-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-22": "target:node-22"
  }
  dockerfile = "22.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/node-cli/22.Dockerfile",
    "org.opencontainers.image.description": "Node.js 22 CLI image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/node-22-cli",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/node-22"
  }
  tags = ["${IMAGE_REPO}/node-22-cli:${TAG}"]
}

target "opensearch-2" {
  inherits = ["default"]
  context = "images/opensearch"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "2.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/opensearch/2.Dockerfile",
    "org.opencontainers.image.description": "OpenSearch 2 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/opensearch-2",
    "org.opencontainers.image.base.name": "docker.io/opensearchproject/opensearch:2"
  }
  tags = ["${IMAGE_REPO}/opensearch-2:${TAG}"]
}

target "php-8-1-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.1.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-fpm/8.1.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.1 FPM image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.1-fpm",
    "org.opencontainers.image.base.name": "docker.io/php:8.1-fpm-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/php-8.1-fpm:${TAG}"]
}

target "php-8-1-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.1-fpm": "target:php-8-1-fpm"
  }
  dockerfile = "8.1.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-cli/8.1.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.1 cli image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.1-cli",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/php-8.1-fpm"
  }
  tags = ["${IMAGE_REPO}/php-8.1-cli:${TAG}"]
}

target "php-8-1-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.1-cli": "target:php-8-1-cli"
  }
  dockerfile = "8.1.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-cli/8.1.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.1 cli image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.1-cli-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/php-8.1-cli"
  }
  tags = ["${IMAGE_REPO}/php-8.1-cli-drupal:${TAG}"]
}

target "php-8-2-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.2.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-fpm/8.2.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.2 FPM image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.2-fpm",
    "org.opencontainers.image.base.name": "docker.io/php:8.2-fpm-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/php-8.2-fpm:${TAG}"]
}

target "php-8-2-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.2-fpm": "target:php-8-2-fpm"
  }
  dockerfile = "8.2.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-cli/8.2.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.2 cli image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.2-cli",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/php-8.2-fpm"
  }
  tags = ["${IMAGE_REPO}/php-8.2-cli:${TAG}"]
}

target "php-8-2-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.2-cli": "target:php-8-2-cli"
  }
  dockerfile = "8.2.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-cli/8.2.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.2 cli image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.2-cli-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/php-8.2-cli"
  }
  tags = ["${IMAGE_REPO}/php-8.2-cli-drupal:${TAG}"]
}

target "php-8-3-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.3.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-fpm/8.3.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.3 FPM image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.3-fpm",
    "org.opencontainers.image.base.name": "docker.io/php:8.3-fpm-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/php-8.3-fpm:${TAG}"]
}

target "php-8-3-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.3-fpm": "target:php-8-3-fpm"
  }
  dockerfile = "8.3.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-cli/8.3.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.3 cli image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.3-cli",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/php-8.3-fpm"
  }
  tags = ["${IMAGE_REPO}/php-8.3-cli:${TAG}"]
}

target "php-8-3-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.3-cli": "target:php-8-3-cli"
  }
  dockerfile = "8.3.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/php-cli/8.3.Dockerfile",
    "org.opencontainers.image.description": "PHP 8.3 cli image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/php-8.3-cli-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/php-8.3-cli"
  }
  tags = ["${IMAGE_REPO}/php-8.3-cli-drupal:${TAG}"]
}

target "postgres-11" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "11.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres/11.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 11 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-11",
    "org.opencontainers.image.base.name": "docker.io/postgres:11-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/postgres-11:${TAG}"]
}

target "postgres-11-ckan" {
  inherits = ["default"]
  context = "images/postgres-ckan"
  contexts = {
    "lagoon/postgres-11": "target:postgres-11"
  }
  dockerfile = "11.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres-ckan/11.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 11 image optimised for CKAN workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-11-ckan",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/postgres-11"
  }
  tags = ["${IMAGE_REPO}/postgres-11-ckan:${TAG}"]
}

target "postgres-11-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-11": "target:postgres-11"
  }
  dockerfile = "11.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres-drupal/11.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 11 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-11-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/postgres-11"
  }
  tags = ["${IMAGE_REPO}/postgres-11-drupal:${TAG}"]
}

target "postgres-12" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "12.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres/12.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 12 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-12",
    "org.opencontainers.image.base.name": "docker.io/postgres:12-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/postgres-12:${TAG}"]
}

target "postgres-12-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-12": "target:postgres-12"
  }
  dockerfile = "12.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres-drupal/12.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 12 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-12-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/postgres-12"
  }
  tags = ["${IMAGE_REPO}/postgres-12-drupal:${TAG}"]
}

target "postgres-13" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "13.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres/13.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 13 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-13",
    "org.opencontainers.image.base.name": "docker.io/postgres:13-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/postgres-13-drupal:${TAG}"]
}

target "postgres-13-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-13": "target:postgres-13"
  }
  dockerfile = "13.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres-drupal/13.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 13 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-13-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/postgres-13"
  }
  tags = ["${IMAGE_REPO}/postgres-13-drupal:${TAG}"]
}

target "postgres-14" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "14.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres/14.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 14 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-14",
    "org.opencontainers.image.base.name": "docker.io/postgres:14-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/postgres-14:${TAG}"]
}

target "postgres-14-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-14": "target:postgres-14"
  }
  dockerfile = "14.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres-drupal/14.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 14 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-14-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/postgres-14"
  }
  tags = ["${IMAGE_REPO}/postgres-14-drupal:${TAG}"]
}

target "postgres-15" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "15.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres/15.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 15 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-15",
    "org.opencontainers.image.base.name": "docker.io/postgres:15-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/postgres-15:${TAG}"]
}

target "postgres-15-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-15": "target:postgres-15"
  }
  dockerfile = "15.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres-drupal/15.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 15 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-15-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/postgres-15"
  }
  tags = ["${IMAGE_REPO}/postgres-15-drupal:${TAG}"]
}

target "postgres-16" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "16.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres/16.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 16 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-16",
    "org.opencontainers.image.base.name": "docker.io/postgres:16-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/postgres-16:${TAG}"]
}

target "postgres-16-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-16": "target:postgres-16"
  }
  dockerfile = "16.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/postgres-drupal/16.Dockerfile",
    "org.opencontainers.image.description": "PostgreSQL 16 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/postgres-16-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/postgres-16"
  }
  tags = ["${IMAGE_REPO}/postgres-16-drupal:${TAG}"]
}

target "python-3-8" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.8.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/python/3.8.Dockerfile",
    "org.opencontainers.image.description": "Python 3.8 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/python-3.8",
    "org.opencontainers.image.base.name": "docker.io/python:3.8-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/python-3.8:${TAG}"]
}

target "python-3-9" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.9.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/python/3.9.Dockerfile",
    "org.opencontainers.image.description": "Python 3.9 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/python-3.9",
    "org.opencontainers.image.base.name": "docker.io/python:3.9-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/python-3.9:${TAG}"]
}

target "python-3-10" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.10.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/python/3.10.Dockerfile",
    "org.opencontainers.image.description": "Python 3.10 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/python-3.10",
    "org.opencontainers.image.base.name": "docker.io/python:3.10-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/python-3.10:${TAG}"]
}

target "python-3-11" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.11.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/python/3.11.Dockerfile",
    "org.opencontainers.image.description": "Python 3.11 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/python-3.11",
    "org.opencontainers.image.base.name": "docker.io/python:3.11-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/python-3.11:${TAG}"]
}

target "python-3-12" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.12.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/python/3.12.Dockerfile",
    "org.opencontainers.image.description": "Python 3.12 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/python-3.12",
    "org.opencontainers.image.base.name": "docker.io/python:3.12-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/python-3.12:${TAG}"]
}

target "rabbitmq" {
  inherits = ["default"]
  context = "images/rabbitmq"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/rabbitmq/Dockerfile",
    "org.opencontainers.image.description": "RabbitMQ image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/rabbitmq",
    "org.opencontainers.image.base.name": "docker.io/rabbitmq:3-management-alpine"
  }
  tags = ["${IMAGE_REPO}/rabbitmq:${TAG}"]
}

target "redis-6" {
  inherits = ["default"]
  context = "images/redis"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/redis/6.Dockerfile",
    "org.opencontainers.image.description": "Redis 6 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/redis-6",
    "org.opencontainers.image.base.name": "docker.io/redis:6-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/redis-6:${TAG}"]
}

target "redis-6-persistent" {
  inherits = ["default"]
  context = "images/redis-persistent"
  contexts = {
    "lagoon/redis-6": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/redis-persistent/6.Dockerfile",
    "org.opencontainers.image.description": "Redis 6 image configured for persistent workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/redis-6-persistent",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/redis-6"
  }
  tags = ["${IMAGE_REPO}/redis-6-persistent:${TAG}"]
}

target "redis-7" {
  inherits = ["default"]
  context = "images/redis"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/redis/7.Dockerfile",
    "org.opencontainers.image.description": "Redis 7 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/redis-7",
    "org.opencontainers.image.base.name": "docker.io/redis:7-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/redis-7:${TAG}"]
}

target "redis-7-persistent" {
  inherits = ["default"]
  context = "images/redis-persistent"
  contexts = {
    "lagoon/redis-7": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/redis-persistent/7.Dockerfile",
    "org.opencontainers.image.description": "Redis 7 image configured for persistent workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/redis-7-persistent",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/redis-7"
  }
  tags = ["${IMAGE_REPO}/redis-7-persistent:${TAG}"]
}

target "ruby-3-1" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.1.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/ruby/3.1.Dockerfile",
    "org.opencontainers.image.description": "Ruby 3.1 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/ruby-3.1",
    "org.opencontainers.image.base.name": "docker.io/ruby:3.1-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/ruby-3.1:${TAG}"]
}

target "ruby-3-2" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.2.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/ruby/3.2.Dockerfile",
    "org.opencontainers.image.description": "Ruby 3.2 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/ruby-3.2",
    "org.opencontainers.image.base.name": "docker.io/ruby:3.2-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/ruby-3.2:${TAG}"]
}

target "ruby-3-3" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.3.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/ruby/3.3.Dockerfile",
    "org.opencontainers.image.description": "Ruby 3.3 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/ruby-3.3",
    "org.opencontainers.image.base.name": "docker.io/ruby:3.3-alpine3.19"
  }
  tags = ["${IMAGE_REPO}/ruby-3.3:${TAG}"]
}

target "solr-8" {
  inherits = ["default"]
  context = "images/solr"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/solr/8.Dockerfile",
    "org.opencontainers.image.description": "Solr 8 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/solr-8",
    "org.opencontainers.image.base.name": "docker.io/solr:8-slim"
  }
  tags = ["${IMAGE_REPO}/solr-8:${TAG}"]
}

target "solr-8-drupal" {
  inherits = ["default"]
  context = "images/solr-drupal"
  contexts = {
    "lagoon/commons": "target:commons",
    "lagoon/solr-8": "target:solr-8"
  }
  dockerfile = "8.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/solr/8.Dockerfile",
    "org.opencontainers.image.description": "Solr 8 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/solr-8-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/solr-8"
  }
  tags = ["${IMAGE_REPO}/solr-8-drupal:${TAG}"]
}

target "solr-9" {
  inherits = ["default"]
  context = "images/solr"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "9.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/solr/9.Dockerfile",
    "org.opencontainers.image.description": "Solr 9 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/solr-9",
    "org.opencontainers.image.base.name": "docker.io/solr:9"
  }
  tags = ["${IMAGE_REPO}/solr-9:${TAG}"]
}

target "solr-9-drupal" {
  inherits = ["default"]
  context = "images/solr-drupal"
  contexts = {
    "lagoon/commons": "target:commons",
    "lagoon/solr-9": "target:solr-9"
  }
  dockerfile = "9.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/solr/9.Dockerfile",
    "org.opencontainers.image.description": "Solr 9 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/solr-9-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/solr-9"
  }
  tags = ["${IMAGE_REPO}/solr-9-drupal:${TAG}"]
}

target "varnish-6" {
  inherits = ["default"]
  context = "images/varnish"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish/6.Dockerfile",
    "org.opencontainers.image.description": "Varnish 6 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-6",
    "org.opencontainers.image.base.name": "docker.io/varnish:6.0"
  }
  tags = ["${IMAGE_REPO}/varnish-6:${TAG}"]
}

target "varnish-6-drupal" {
  inherits = ["default"]
  context = "images/varnish-drupal"
  contexts = {
    "lagoon/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish-drupal/6.Dockerfile",
    "org.opencontainers.image.description": "Varnish 6 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-6-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/varnish-6"
  }
  tags = ["${IMAGE_REPO}/varnish-6-drupal:${TAG}"]
}

target "varnish-6-persistent" {
  inherits = ["default"]
  context = "images/varnish-persistent"
  contexts = {
    "lagoon/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish-persistent/6.Dockerfile",
    "org.opencontainers.image.description": "Varnish 6 image configured for persistent workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-6-persistent",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/varnish-6"
  }
  tags = ["${IMAGE_REPO}/varnish-6-persistent:${TAG}"]
}

target "varnish-6-persistent-drupal" {
  inherits = ["default"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "lagoon/varnish-6-drupal": "target:varnish-6-drupal"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish-persistent-drupal/6.Dockerfile",
    "org.opencontainers.image.description": "Varnish 6 image configured for persistent Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-6-persistent-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/varnish-6-drupal"
  }
  tags = ["${IMAGE_REPO}/varnish-6-persistent-drupal:${TAG}"]
}

target "varnish-7" {
  inherits = ["default"]
  context = "images/varnish"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish/7.Dockerfile",
    "org.opencontainers.image.description": "Varnish 7 image optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-7",
    "org.opencontainers.image.base.name": "docker.io/varnish:7-alpine"
  }
  tags = ["${IMAGE_REPO}/varnish-7:${TAG}"]
}

target "varnish-7-drupal" {
  inherits = ["default"]
  context = "images/varnish-drupal"
  contexts = {
    "lagoon/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish-drupal/7.Dockerfile",
    "org.opencontainers.image.description": "Varnish 7 image optimised for Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-7-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/varnish-7"
  }
  tags = ["${IMAGE_REPO}/varnish-7-drupal:${TAG}"]
}

target "varnish-7-persistent" {
  inherits = ["default"]
  context = "images/varnish-persistent"
  contexts = {
    "lagoon/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish-persistent/7.Dockerfile",
    "org.opencontainers.image.description": "Varnish 7 image configured for persistent workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-7-persistent",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/varnish-7"
  }
  tags = ["${IMAGE_REPO}/varnish-7-persistent:${TAG}"]
}

target "varnish-7-persistent-drupal" {
  inherits = ["default"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "lagoon/varnish-7-drupal": "target:varnish-7-drupal"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images/blob/${TAG}/images/varnish-persistent-drupal/7.Dockerfile",
    "org.opencontainers.image.description": "Varnish 7 image configured for persistent Drupal workloads running in Lagoon in production and locally",
    "org.opencontainers.image.title": "${IMAGE_REPO}/varnish-7-persistent-drupal",
    "org.opencontainers.image.base.name": "docker.io/uselagoon/varnish-7-drupal"
  }
  tags = ["${IMAGE_REPO}/varnish-7-persistent-drupal:${TAG}"]
}
