# docker-bake.dev.hcl
# docker-bake.dev.hcl
variable "TAG" {
  default = "latest"
}

variable "LAGOON_VERSION" {
  default = "development"
}

variable "IMAGE_REPO" {
  default = "lagoon"
}

variable "IMAGE_TAG" {
  default = "newest"
}

variable "PUSH_REPO" {
  default = "lagoon"
}

variable "PUSH_TAG" {
  default = "newest"
}

variable "PLATFORMS" {
  // use PLATFORMS=linux/amd64,linux/arm64 to override default single architecture on the cli
  default = "linux/amd64"
}

target "default"{
  platforms = ["${PLATFORMS}"]
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.source": "https://github.com/uselagoon/lagoon-images",
    "org.opencontainers.image.url": "https://github.com/uselagoon/lagoon-images",
    "org.opencontainers.image.description": "Docker images optimised for running in Lagoon in production and locally",
    "org.opencontainers.image.licenses": "Apache 2.0",
    "org.opencontainers.image.version": "${LAGOON_VERSION}",
    "repository": "https://github.com/uselagoon/lagoon-images"
  }
  args = {
    LAGOON_VERSION = "${LAGOON_VERSION}"
    PUSH_REPO = "${PUSH_REPO}"
    PUSH_TAG = "${PUSH_TAG}"
    IMAGE_REPO = "${IMAGE_REPO}"
    IMAGE_TAG = "${IMAGE_TAG}"
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
    "nginx",
    "nginx-drupal",
    "node-18",
    "node-18-builder",
    "node-18-cli",
    "node-20",
    "node-20-builder",
    "node-20-cli",
    "opensearch-2",
    "php-8-0-fpm",
    "php-8-0-cli",
    "php-8-0-cli-drupal",
    "php-8-1-fpm",
    "php-8-1-cli",
    "php-8-1-cli-drupal",
    "php-8-2-fpm",
    "php-8-2-cli",
    "php-8-2-cli-drupal",
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
    "rabbitmq-cluster",
    "redis-6",
    "redis-6-persistent",
    "redis-7",
    "redis-7-persistent",
    "ruby-3-0",
    "ruby-3-1",
    "ruby-3-2",
    "solr-7",
    "solr-7-drupal",
    "solr-8",
    "solr-8-drupal",
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
    "mariadb-10-11-drupal",
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
  ]
}

group "php" {
  targets = [
    "commons", 
    "php-8-0-fpm",
    "php-8-0-cli",
    "php-8-0-cli-drupal",
    "php-8-1-fpm",
    "php-8-1-cli",
    "php-8-1-cli-drupal",
    "php-8-2-fpm",
    "php-8-2-cli",
    "php-8-2-cli-drupal"
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
    "ruby-3-0",
    "ruby-3-1",
    "ruby-3-2"
  ]
}

group "solr" {
  targets = [
    "commons", 
    "solr-7",
    "solr-7-drupal",
    "solr-8",
    "solr-8-drupal"
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
    "rabbitmq",
    "rabbitmq-cluster"
  ]
}

target "commons" {
  inherits = ["default"]
  context = "images/commons"
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/commons"
  }
  tags = [
    "${IMAGE_REPO}/commons:${IMAGE_TAG}",
    "${PUSH_REPO}/commons:${PUSH_TAG}"
  ]
}

target "mariadb-10-4" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.4.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.4"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.4:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.4:${PUSH_TAG}"
  ]
}

target "mariadb-10-4-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.4": "target:mariadb-10-4"
  }
  dockerfile = "10.4.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.4-drupal"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.4-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.4-drupal:${PUSH_TAG}"
  ]
}

target "mariadb-10-5" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.5.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.5"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.5:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.5:${PUSH_TAG}"
  ]
}

target "mariadb-10-5-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.5": "target:mariadb-10-5"
  }
  dockerfile = "10.5.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.4-drupal"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.5-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.5-drupal:${PUSH_TAG}"
  ]
}

target "mariadb-10-6" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.6"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.6:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.6:${PUSH_TAG}"
  ]
}

target "mariadb-10-6-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.6": "target:mariadb-10-6"
  }
  dockerfile = "10.6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.6-drupal"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.6-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.6-drupal:${PUSH_TAG}"
  ]
}

target "mariadb-10-11" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.11.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.11"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.11:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.11:${PUSH_TAG}"
  ]
}

target "mariadb-10-11-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.11": "target:mariadb-10-6"
  }
  dockerfile = "10.11.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mariadb-10.11-drupal"
  }
  tags = [
    "${IMAGE_REPO}/mariadb-10.11-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/mariadb-10.11-drupal:${PUSH_TAG}"
  ]
}

target "mongo-4" {
  inherits = ["default"]
  context = "images/mongo"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "4.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/mongo-4"
  }
  tags = [
    "${IMAGE_REPO}/mongo-4:${IMAGE_TAG}",
    "${PUSH_REPO}/mongo-4:${PUSH_TAG}"
  ]
}

target "nginx" {
  inherits = ["default"]
  context = "images/nginx"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/nginx"
  }
  tags = [
    "${IMAGE_REPO}/nginx:${IMAGE_TAG}",
    "${PUSH_REPO}/nginx:${PUSH_TAG}"
  ]
}

target "nginx-drupal" {
  inherits = ["default"]
  context = "images/nginx-drupal"
  contexts = {
    "lagoon/nginx": "target:nginx"
  }
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/nginx-drupal"
  }
  tags = [
    "${IMAGE_REPO}/nginx-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/nginx-drupal:${PUSH_TAG}"
  ]
}

target "node-18" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "18.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/node-18"
  }
  tags = [
    "${IMAGE_REPO}/node-18:${IMAGE_TAG}",
    "${PUSH_REPO}/node-18:${PUSH_TAG}"
  ]
}

target "node-18-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-18": "target:node-18"
  }
  dockerfile = "18.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/node-18-builder"
  }
  tags = [
    "${IMAGE_REPO}/node-18-builder:${IMAGE_TAG}",
    "${PUSH_REPO}/node-18-builder:${PUSH_TAG}"
  ]
}

target "node-18-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-18": "target:node-18"
  }
  dockerfile = "18.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/node-18-cli"
  }
  tags = [
    "${IMAGE_REPO}/node-18-cli:${IMAGE_TAG}",
    "${PUSH_REPO}/node-18-cli:${PUSH_TAG}"
  ]
}

target "node-20" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "20.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/node-20"
  }
  tags = [
    "${IMAGE_REPO}/node-20:${IMAGE_TAG}",
    "${PUSH_REPO}/node-20:${PUSH_TAG}"
  ]
}

target "node-20-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/node-20-builder"
  }
  tags = [
    "${IMAGE_REPO}/node-20-builder:${IMAGE_TAG}",
    "${PUSH_REPO}/node-20-builder:${PUSH_TAG}"
  ]
}

target "node-20-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/node-20-cli"
  }
  tags = [
    "${IMAGE_REPO}/node-20-cli:${IMAGE_TAG}",
    "${PUSH_REPO}/node-20-cli:${PUSH_TAG}"
  ]
}

target "opensearch-2" {
  inherits = ["default"]
  context = "images/opensearch"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "2.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/opensearch-2"
  }
  tags = [
    "${IMAGE_REPO}/opensearch-2:${IMAGE_TAG}",
    "${PUSH_REPO}/opensearch-2:${PUSH_TAG}"
  ]
}

target "php-8-0-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.0.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.0-fpm"
  }
  tags = [
    "${IMAGE_REPO}/php-8.0-fpm:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.0-fpm:${PUSH_TAG}"
  ]
}

target "php-8-0-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.0-fpm": "target:php-8-0-fpm"
  }
  dockerfile = "8.0.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.0-cli"
  }
  tags = [
    "${IMAGE_REPO}/php-8.0-cli:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.0-cli:${PUSH_TAG}"
  ]
}

target "php-8-0-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.0-cli": "target:php-8-0-cli"
  }
  dockerfile = "8.0.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.0-cli-drupal"
  }
  tags = [
    "${IMAGE_REPO}/php-8.0-cli-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.0-cli-drupal:${PUSH_TAG}"
  ]
}

target "php-8-1-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.1.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.1-fpm"
  }
  tags = [
    "${IMAGE_REPO}/php-8.1-fpm:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.1-fpm:${PUSH_TAG}"
  ]
}

target "php-8-1-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.1-fpm": "target:php-8-1-fpm"
  }
  dockerfile = "8.1.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.1-cli"
  }
  tags = [
    "${IMAGE_REPO}/php-8.1-cli:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.1-cli:${PUSH_TAG}"
  ]
}

target "php-8-1-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.1-cli": "target:php-8-1-cli"
  }
  dockerfile = "8.1.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.1-cli-drupal"
  }
  tags = [
    "${IMAGE_REPO}/php-8.1-cli-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.1-cli-drupal:${PUSH_TAG}"
  ]
}

target "php-8-2-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.2.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.2-fpm"
  }
  tags = [
    "${IMAGE_REPO}/php-8.2-fpm:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.2-fpm:${PUSH_TAG}"
  ]
}

target "php-8-2-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.2-fpm": "target:php-8-2-fpm"
  }
  dockerfile = "8.2.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.2-cli"
  }
  tags = [
    "${IMAGE_REPO}/php-8.2-cli:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.2-cli:${PUSH_TAG}"
  ]
}

target "php-8-2-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.2-cli": "target:php-8-2-cli"
  }
  dockerfile = "8.2.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/php-8.2-cli-drupal"
  }
  tags = [
    "${IMAGE_REPO}/php-8.2-cli-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/php-8.2-cli-drupal:${PUSH_TAG}"
  ]
}

target "postgres-11" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "11.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-11"
  }
  tags = [
    "${IMAGE_REPO}/postgres-11:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-11:${PUSH_TAG}"
  ]
}

target "postgres-11-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-11": "target:postgres-11"
  }
  dockerfile = "11.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-11-drupal"
  }
  tags = [
    "${IMAGE_REPO}/postgres-11-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-11-drupal:${PUSH_TAG}"
  ]
}

target "postgres-11-ckan" {
  inherits = ["default"]
  context = "images/postgres-ckan"
  contexts = {
    "lagoon/postgres-11": "target:postgres-11"
  }
  dockerfile = "11.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-11-ckan"
  }
  tags = [
    "${IMAGE_REPO}/postgres-11-ckan:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-11-ckan:${PUSH_TAG}"
  ]
}

target "postgres-12" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "12.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-12"
  }
  tags = [
    "${IMAGE_REPO}/postgres-12:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-12:${PUSH_TAG}"
  ]
}

target "postgres-12-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-12": "target:postgres-12"
  }
  dockerfile = "12.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-12-drupal"
  }
  tags = [
    "${IMAGE_REPO}/postgres-12-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-12-drupal:${PUSH_TAG}"
  ]
}

target "postgres-13" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "13.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-13"
  }
  tags = [
    "${IMAGE_REPO}/postgres-13:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-13:${PUSH_TAG}"
  ]
}

target "postgres-13-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-13": "target:postgres-13"
  }
  dockerfile = "13.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-13-drupal"
  }
  tags = [
    "${IMAGE_REPO}/postgres-13-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-13-drupal:${PUSH_TAG}"
  ]
}

target "postgres-14" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "14.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-14"
  }
  tags = [
    "${IMAGE_REPO}/postgres-14:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-14:${PUSH_TAG}"
  ]
}

target "postgres-14-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-14": "target:postgres-14"
  }
  dockerfile = "14.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-14-drupal"
  }
  tags = [
    "${IMAGE_REPO}/postgres-14-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-14-drupal:${PUSH_TAG}"
  ]
}

target "postgres-15" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "15.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-15"
  }
  tags = [
    "${IMAGE_REPO}/postgres-15:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-15:${PUSH_TAG}"
  ]
}

target "postgres-15-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-15": "target:postgres-15"
  }
  dockerfile = "15.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-15-drupal"
  }
  tags = [
    "${IMAGE_REPO}/postgres-15-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-15-drupal:${PUSH_TAG}"
  ]
}

target "postgres-16" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "16.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-16"
  }
  tags = [
    "${IMAGE_REPO}/postgres-16:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-16:${PUSH_TAG}"
  ]
}

target "postgres-16-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-16": "target:postgres-16"
  }
  dockerfile = "16.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/postgres-16-drupal"
  }
  tags = [
    "${IMAGE_REPO}/postgres-16-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/postgres-16-drupal:${PUSH_TAG}"
  ]
}

target "python-3-8" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.8.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/python-3.8"
  }
  tags = [
    "${IMAGE_REPO}/python-3.8:${IMAGE_TAG}",
    "${PUSH_REPO}/python-3.8:${PUSH_TAG}"
  ]
}

target "python-3-9" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.9.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/python-3.9"
  }
  tags = [
    "${IMAGE_REPO}/python-3.9:${IMAGE_TAG}",
    "${PUSH_REPO}/python-3.9:${PUSH_TAG}"
  ]
}

target "python-3-10" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.10.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/python-3.10"
  }
  tags = [
    "${IMAGE_REPO}/python-3.10:${IMAGE_TAG}",
    "${PUSH_REPO}/python-3.10:${PUSH_TAG}"
  ]
}

target "python-3-11" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.11.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/python-3.11"
  }
  tags = [
    "${IMAGE_REPO}/python-3.11:${IMAGE_TAG}",
    "${PUSH_REPO}/python-3.11:${PUSH_TAG}"
  ]
}

target "python-3-12" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.12.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/python-3.12"
  }
  tags = [
    "${IMAGE_REPO}/python-3.12:${IMAGE_TAG}",
    "${PUSH_REPO}/python-3.12:${PUSH_TAG}"
  ]
}

target "rabbitmq" {
  inherits = ["default"]
  context = "images/rabbitmq"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/rabbitmq"
  }
  tags = [
    "${IMAGE_REPO}/rabbitmq:${IMAGE_TAG}",
    "${PUSH_REPO}/rabbitmq:${PUSH_TAG}"
  ]
}

target "rabbitmq-cluster" {
  inherits = ["default"]
  context = "images/rabbitmq-cluster"
  contexts = {
    "lagoon/rabbitmq": "target:rabbitmq"
  }
  dockerfile = "Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/rabbitmq-cluster"
  }
  tags = [
    "${IMAGE_REPO}/rabbitmq-cluster:${IMAGE_TAG}",
    "${PUSH_REPO}/rabbitmq-cluster:${PUSH_TAG}"
  ]
}

target "redis-6" {
  inherits = ["default"]
  context = "images/redis"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/redis-6"
  }
  tags = [
    "${IMAGE_REPO}/redis-6:${IMAGE_TAG}",
    "${PUSH_REPO}/redis-6:${PUSH_TAG}"
  ]
}

target "redis-6-persistent" {
  inherits = ["default"]
  context = "images/redis-persistent"
  contexts = {
    "lagoon/redis-6": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/redis-6-persistent"
  }
  tags = [
    "${IMAGE_REPO}/redis-6-persistent:${IMAGE_TAG}",
    "${PUSH_REPO}/redis-6-persistent:${PUSH_TAG}"
  ]
}

target "redis-7" {
  inherits = ["default"]
  context = "images/redis"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/redis-7"
  }
  tags = [
    "${IMAGE_REPO}/redis-7:${IMAGE_TAG}",
    "${PUSH_REPO}/redis-7:${PUSH_TAG}"
  ]
}

target "redis-7-persistent" {
  inherits = ["default"]
  context = "images/redis-persistent"
  contexts = {
    "lagoon/redis-7": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/redis-7-persistent"
  }
  tags = [
    "${IMAGE_REPO}/redis-7-persistent:${IMAGE_TAG}",
    "${PUSH_REPO}/redis-7-persistent:${PUSH_TAG}"
  ]
}

target "ruby-3-0" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.0.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/ruby-3.0"
  }
  tags = [
    "${IMAGE_REPO}/ruby-3.0:${IMAGE_TAG}",
    "${PUSH_REPO}/ruby-3.0:${PUSH_TAG}"
  ]
}

target "ruby-3-1" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.1.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/ruby-3.1"
  }
  tags = [
    "${IMAGE_REPO}/ruby-3.1:${IMAGE_TAG}",
    "${PUSH_REPO}/ruby-3.1:${PUSH_TAG}"
  ]
}

target "ruby-3-2" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.2.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/ruby-3.2"
  }
  tags = [
    "${IMAGE_REPO}/ruby-3.2:${IMAGE_TAG}",
    "${PUSH_REPO}/ruby-3.2:${PUSH_TAG}"
  ]
}

target "solr-7" {
  inherits = ["default"]
  context = "images/solr"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/solr-7"
  }
  tags = [
    "${IMAGE_REPO}/solr-7:${IMAGE_TAG}",
    "${PUSH_REPO}/solr-7:${PUSH_TAG}"
  ]
}

target "solr-7-drupal" {
  inherits = ["default"]
  context = "images/solr-drupal"
  contexts = {
    "lagoon/solr-7": "target:solr-7"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/solr-7-drupal"
  }
  tags = [
    "${IMAGE_REPO}/solr-7-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/solr-7-drupal:${PUSH_TAG}"
  ]
}

target "solr-8" {
  inherits = ["default"]
  context = "images/solr"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/solr-8"
  }
  tags = [
    "${IMAGE_REPO}/solr-8:${IMAGE_TAG}",
    "${PUSH_REPO}/solr-8:${PUSH_TAG}"
  ]
}

target "solr-8-drupal" {
  inherits = ["default"]
  context = "images/solr-drupal"
  contexts = {
    "lagoon/solr-8": "target:solr-8"
  }
  dockerfile = "8.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/solr-8-drupal"
  }
  tags = [
    "${IMAGE_REPO}/solr-8-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/solr-8-drupal:${PUSH_TAG}"
  ]
}

target "varnish-6" {
  inherits = ["default"]
  context = "images/varnish"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-6"
  }
  tags = [
    "${IMAGE_REPO}/varnish-6:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-6:${PUSH_TAG}"
  ]
}

target "varnish-6-drupal" {
  inherits = ["default"]
  context = "images/varnish-drupal"
  contexts = {
    "lagoon/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-6-drupal"
  }
  tags = [
    "${IMAGE_REPO}/varnish-6-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-6-drupal:${PUSH_TAG}"
  ]
}

target "varnish-6-persistent" {
  inherits = ["default"]
  context = "images/varnish-persistent"
  contexts = {
    "lagoon/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-6-persistent"
  }
  tags = [
    "${IMAGE_REPO}/varnish-6-persistent:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-6-persistent:${PUSH_TAG}"
  ]
}

target "varnish-6-persistent-drupal" {
  inherits = ["default"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "lagoon/varnish-6-drupal": "target:varnish-6-drupal"
  }
  dockerfile = "6.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-6-persistent-drupal"
  }
  tags = [
    "${IMAGE_REPO}/varnish-6-persistent-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-6-persistent-drupal:${PUSH_TAG}"
  ]
}

target "varnish-7" {
  inherits = ["default"]
  context = "images/varnish"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-7"
  }
  tags = [
    "${IMAGE_REPO}/varnish-7:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-7:${PUSH_TAG}"
  ]
}

target "varnish-7-drupal" {
  inherits = ["default"]
  context = "images/varnish-drupal"
  contexts = {
    "lagoon/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-7-drupal"
  }
  tags = [
    "${IMAGE_REPO}/varnish-7-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-7-drupal:${PUSH_TAG}"
  ]
}

target "varnish-7-persistent" {
  inherits = ["default"]
  context = "images/varnish-persistent"
  contexts = {
    "lagoon/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-7-persistent"
  }
  tags = [
    "${IMAGE_REPO}/varnish-7-persistent:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-7-persistent:${PUSH_TAG}"
  ]
}

target "varnish-7-persistent-drupal" {
  inherits = ["default"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "lagoon/varnish-7-drupal": "target:varnish-7-drupal"
  }
  dockerfile = "7.Dockerfile"
  labels = {
    "org.opencontainers.image.title": "lagoon-images/varnish-7-persistent-drupal"
  }
  tags = [
    "${IMAGE_REPO}/varnish-7-persistent-drupal:${IMAGE_TAG}",
    "${PUSH_REPO}/varnish-7-persistent-drupal:${PUSH_TAG}"
  ]
}
