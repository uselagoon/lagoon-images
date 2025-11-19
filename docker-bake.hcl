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

variable "NO_CACHE" {
  default = "false"
}

target "default"{
  no-cache = "${NO_CACHE}"
  platforms = ["${PLATFORMS}"]
  labels = {
    "org.opencontainers.image.authors": "The Lagoon Authors"
    "org.opencontainers.image.url": "https://github.com/uselagoon/lagoon-images",
    "org.opencontainers.image.licenses": "Apache 2.0",
    "org.opencontainers.image.version": "${LAGOON_VERSION}",
    "repository": "https://github.com/uselagoon/lagoon-images"
  }
  args = {
    LAGOON_VERSION = "${LAGOON_VERSION}"
    UPSTREAM_REPO = "${UPSTREAM_REPO}"
    UPSTREAM_TAG = "${UPSTREAM_TAG}"
    IMAGE_REPO = "${IMAGE_REPO}"
  }
}

group "default" {
  targets = [
    "commons", 
    "mariadb-10-6",
    "mariadb-10-6-drupal",
    "mariadb-10-11",
    "mariadb-10-11-drupal",
    "mariadb-11-4",
    "mongo-4",
    "mysql-8-0",
    "mysql-8-4",
    "nginx",
    "nginx-drupal",
    "node-20",
    "node-20-builder",
    "node-20-cli",
    "node-22",
    "node-22-builder",
    "node-22-cli",
    "node-24",
    "node-24-builder",
    "node-24-cli",
    "opensearch-2",
    "opensearch-3",
    "php-8-1-fpm",
    "php-8-1-cli",
    "php-8-1-cli-drupal",
    "php-8-2-fpm",
    "php-8-2-cli",
    "php-8-2-cli-drupal",
    "php-8-3-fpm",
    "php-8-3-cli",
    "php-8-3-cli-drupal",
    "php-8-4-fpm",
    "php-8-4-cli",
    "php-8-4-cli-drupal",
    "postgres-13",
    "postgres-13-drupal",
    "postgres-14",
    "postgres-14-drupal",
    "postgres-15",
    "postgres-15-drupal",
    "postgres-16",
    "postgres-16-drupal",
    "postgres-17",
    "postgres-17-drupal",
    "python-3-9",
    "python-3-10",
    "python-3-11",
    "python-3-12",
    "python-3-13",
    "python-3-14",
    "rabbitmq",
    "rabbitmq-cluster",
    "redis-7",
    "redis-7-persistent",
    "redis-8",
    "ruby-3-2",
    "ruby-3-3",
    "ruby-3-4",
    "solr-9",
    "solr-9-drupal",
    "valkey-8",
    "valkey-9",
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
    "mariadb-10-6",
    "mariadb-10-6-drupal",
    "mariadb-10-11",
    "mariadb-10-11-drupal",
    "mariadb-11-4"
  ]
}

group "mongo" {
    targets = [
        "commons",
        "mongo-4"
    ]
}

group "mysql" {
  targets = [
    "commons", 
    "mysql-8-0",
    "mysql-8-4"
  ]
}

group "nginx" {
  targets = [
    "commons", 
    "nginx",
    "nginx-drupal"
  ]
}

group "node" {
  targets = [
    "commons", 
    "node-20",
    "node-20-builder",
    "node-20-cli",
    "node-22",
    "node-22-builder",
    "node-22-cli",
    "node-24",
    "node-24-builder",
    "node-24-cli"
  ]
}

group "opensearch" {
  targets = [
    "commons", 
    "opensearch-2",
    "opensearch-3"
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
    "php-8-3-cli-drupal",
    "php-8-4-fpm",
    "php-8-4-cli",
    "php-8-4-cli-drupal",
  ]
}

group "postgres" {
  targets = [
    "commons", 
    "postgres-13",
    "postgres-13-drupal",
    "postgres-14",
    "postgres-14-drupal",
    "postgres-15",
    "postgres-15-drupal",
    "postgres-16",
    "postgres-16-drupal",
    "postgres-17",
    "postgres-17-drupal",
  ]
}

group "python" {
  targets = [
    "commons", 
    "python-3-9",
    "python-3-10",
    "python-3-11",
    "python-3-12",
    "python-3-13",
    "python-3-14"
  ]
}

group "rabbitmq" {
  targets = [
    "commons", 
    "rabbitmq",
    "rabbitmq-cluster"
  ]
}

group "redis" {
  targets = [
    "commons", 
    "redis-7",
    "redis-7-persistent",
    "redis-8"
  ]
}

group "ruby" {
  targets = [
    "commons", 
    "ruby-3-2",
    "ruby-3-3",
    "ruby-3-4",
  ]
}

group "solr" {
  targets = [
    "commons", 
    "solr-9",
    "solr-9-drupal",
  ]
}

group "valkey" {
  targets = [
    "commons", 
    "valkey-8",
    "valkey-9"
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

target "commons" {
  inherits = ["default"]
  context = "images/commons"
  dockerfile = "Dockerfile"
  tags = ["${IMAGE_REPO}/commons:${TAG}"]
}

target "mariadb-10-6" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "10.6.Dockerfile"
  tags = ["${IMAGE_REPO}/mariadb-10.6:${TAG}"]
}

target "mariadb-10-6-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "${IMAGE_REPO}/mariadb-10.6": "target:mariadb-10-6"
  }
  dockerfile = "10.6.Dockerfile"
  tags = ["${IMAGE_REPO}/mariadb-10.6-drupal:${TAG}"]
}

target "mariadb-10-11" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "10.11.Dockerfile"
  tags = ["${IMAGE_REPO}/mariadb-10.11:${TAG}"]
}

target "mariadb-10-11-drupal" {
  inherits = ["default"]
  context = "images/mariadb-drupal"
  contexts = {
    "${IMAGE_REPO}/mariadb-10.11": "target:mariadb-10-11"
  }
  dockerfile = "10.11.Dockerfile"
  tags = ["${IMAGE_REPO}/mariadb-10.11-drupal:${TAG}"]
}

target "mariadb-11-4" {
  inherits = ["default"]
  context = "images/mariadb"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "11.4.Dockerfile"
  tags = ["${IMAGE_REPO}/mariadb-11.4:${TAG}"]
}


target "mongo-4" {
  inherits = ["default"]
  context = "images/mongo"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "4.Dockerfile"
  tags = ["${IMAGE_REPO}/mongo-4:${TAG}"]
}

target "mysql-8-0" {
  inherits = ["default"]
  context = "images/mysql"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.0.Dockerfile"
  tags = ["${IMAGE_REPO}/mysql-8.0:${TAG}"]
}

target "mysql-8-4" {
  inherits = ["default"]
  context = "images/mysql"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["${IMAGE_REPO}/mysql-8.4:${TAG}"]
}

target "nginx" {
  inherits = ["default"]
  context = "images/nginx"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  tags = ["${IMAGE_REPO}/nginx:${TAG}"]
}

target "nginx-drupal" {
  inherits = ["default"]
  context = "images/nginx-drupal"
  contexts = {
    "${IMAGE_REPO}/nginx": "target:nginx"
  }
  dockerfile = "Dockerfile"
  tags = ["${IMAGE_REPO}/nginx-drupal:${TAG}"]
}

target "node-20" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "20.Dockerfile"
  tags = ["${IMAGE_REPO}/node-20:${TAG}"]
}

target "node-20-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "${IMAGE_REPO}/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  tags = ["${IMAGE_REPO}/node-20-builder:${TAG}"]
}

target "node-20-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "${IMAGE_REPO}/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  tags = ["${IMAGE_REPO}/node-20-cli:${TAG}"]
}

target "node-22" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "22.Dockerfile"
  tags = ["${IMAGE_REPO}/node-22:${TAG}"]
}

target "node-22-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "${IMAGE_REPO}/node-22": "target:node-22"
  }
  dockerfile = "22.Dockerfile"
  tags = ["${IMAGE_REPO}/node-22-builder:${TAG}"]
}

target "node-22-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "${IMAGE_REPO}/node-22": "target:node-22"
  }
  dockerfile = "22.Dockerfile"
  tags = ["${IMAGE_REPO}/node-22-cli:${TAG}"]
}

target "node-24" {
  inherits = ["default"]
  context = "images/node"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "24.Dockerfile"
  tags = ["${IMAGE_REPO}/node-24:${TAG}"]
}

target "node-24-builder" {
  inherits = ["default"]
  context = "images/node-builder"
  contexts = {
    "${IMAGE_REPO}/node-24": "target:node-24"
  }
  dockerfile = "24.Dockerfile"
  tags = ["${IMAGE_REPO}/node-24-builder:${TAG}"]
}

target "node-24-cli" {
  inherits = ["default"]
  context = "images/node-cli"
  contexts = {
    "${IMAGE_REPO}/node-24": "target:node-24"
  }
  dockerfile = "24.Dockerfile"
  tags = ["${IMAGE_REPO}/node-24-cli:${TAG}"]
}

target "opensearch-2" {
  inherits = ["default"]
  context = "images/opensearch"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "2.Dockerfile"
  tags = ["${IMAGE_REPO}/opensearch-2:${TAG}"]
}

target "opensearch-3" {
  inherits = ["default"]
  context = "images/opensearch"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.Dockerfile"
  tags = ["${IMAGE_REPO}/opensearch-3:${TAG}"]
}

target "php-8-1-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.1.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.1-fpm:${TAG}"]
}

target "php-8-1-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "${IMAGE_REPO}/php-8.1-fpm": "target:php-8-1-fpm"
  }
  dockerfile = "8.1.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.1-cli:${TAG}"]
}

target "php-8-1-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "${IMAGE_REPO}/php-8.1-cli": "target:php-8-1-cli"
  }
  dockerfile = "8.1.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.1-cli-drupal:${TAG}"]
}

target "php-8-2-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.2.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.2-fpm:${TAG}"]
}

target "php-8-2-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "${IMAGE_REPO}/php-8.2-fpm": "target:php-8-2-fpm"
  }
  dockerfile = "8.2.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.2-cli:${TAG}"]
}

target "php-8-2-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "${IMAGE_REPO}/php-8.2-cli": "target:php-8-2-cli"
  }
  dockerfile = "8.2.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.2-cli-drupal:${TAG}"]
}

target "php-8-3-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.3.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.3-fpm:${TAG}"]
}

target "php-8-3-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "${IMAGE_REPO}/php-8.3-fpm": "target:php-8-3-fpm"
  }
  dockerfile = "8.3.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.3-cli:${TAG}"]
}

target "php-8-3-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "${IMAGE_REPO}/php-8.3-cli": "target:php-8-3-cli"
  }
  dockerfile = "8.3.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.3-cli-drupal:${TAG}"]
}

target "php-8-4-fpm" {
  inherits = ["default"]
  context = "images/php-fpm"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.4-fpm:${TAG}"]
}

target "php-8-4-cli" {
  inherits = ["default"]
  context = "images/php-cli"
  contexts = {
    "${IMAGE_REPO}/php-8.4-fpm": "target:php-8-4-fpm"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.4-cli:${TAG}"]
}

target "php-8-4-cli-drupal" {
  inherits = ["default"]
  context = "images/php-cli-drupal"
  contexts = {
    "${IMAGE_REPO}/php-8.4-cli": "target:php-8-4-cli"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["${IMAGE_REPO}/php-8.4-cli-drupal:${TAG}"]
}

target "postgres-13" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "13.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-13:${TAG}"]
}

target "postgres-13-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "${IMAGE_REPO}/postgres-13": "target:postgres-13"
  }
  dockerfile = "13.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-13-drupal:${TAG}"]
}

target "postgres-14" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "14.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-14:${TAG}"]
}

target "postgres-14-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "${IMAGE_REPO}/postgres-14": "target:postgres-14"
  }
  dockerfile = "14.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-14-drupal:${TAG}"]
}

target "postgres-15" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "15.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-15:${TAG}"]
}

target "postgres-15-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "${IMAGE_REPO}/postgres-15": "target:postgres-15"
  }
  dockerfile = "15.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-15-drupal:${TAG}"]
}

target "postgres-16" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "16.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-16:${TAG}"]
}

target "postgres-16-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "${IMAGE_REPO}/postgres-16": "target:postgres-16"
  }
  dockerfile = "16.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-16-drupal:${TAG}"]
}

target "postgres-17" {
  inherits = ["default"]
  context = "images/postgres"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "17.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-17:${TAG}"]
}

target "postgres-17-drupal" {
  inherits = ["default"]
  context = "images/postgres-drupal"
  contexts = {
    "${IMAGE_REPO}/postgres-17": "target:postgres-17"
  }
  dockerfile = "17.Dockerfile"
  tags = ["${IMAGE_REPO}/postgres-17-drupal:${TAG}"]
}

target "python-3-9" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.9.Dockerfile"
  tags = ["${IMAGE_REPO}/python-3.9:${TAG}"]
}


target "python-3-10" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.10.Dockerfile"
  tags = ["${IMAGE_REPO}/python-3.10:${TAG}"]
}

target "python-3-11" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.11.Dockerfile"
  tags = ["${IMAGE_REPO}/python-3.11:${TAG}"]
}

target "python-3-12" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.12.Dockerfile"
  tags = ["${IMAGE_REPO}/python-3.12:${TAG}"]
}

target "python-3-13" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.13.Dockerfile"
  tags = ["${IMAGE_REPO}/python-3.13:${TAG}"]
}

target "python-3-14" {
  inherits = ["default"]
  context = "images/python"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.14.Dockerfile"
  tags = ["${IMAGE_REPO}/python-3.14:${TAG}"]
}

target "rabbitmq" {
  inherits = ["default"]
  context = "images/rabbitmq"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  tags = ["${IMAGE_REPO}/rabbitmq:${TAG}"]
}

target "rabbitmq-cluster" {
  inherits = ["default"]
  context = "images/rabbitmq-cluster"
  contexts = {
    "${IMAGE_REPO}/rabbitmq": "target:rabbitmq"
  }
  dockerfile = "Dockerfile"
  tags = ["${IMAGE_REPO}/rabbitmq-cluster:${TAG}"]
}

target "redis-7" {
  inherits = ["default"]
  context = "images/redis"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  tags = ["${IMAGE_REPO}/redis-7:${TAG}"]
}

target "redis-7-persistent" {
  inherits = ["default"]
  context = "images/redis-persistent"
  contexts = {
    "${IMAGE_REPO}/redis-7": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  tags = ["${IMAGE_REPO}/redis-7-persistent:${TAG}"]
}

target "redis-8" {
  inherits = ["default"]
  context = "images/redis"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.Dockerfile"
  tags = ["${IMAGE_REPO}/redis-8:${TAG}"]
}

target "ruby-3-2" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.2.Dockerfile"
  tags = ["${IMAGE_REPO}/ruby-3.2:${TAG}"]
}

target "ruby-3-3" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.3.Dockerfile"
  tags = ["${IMAGE_REPO}/ruby-3.3:${TAG}"]
}

target "ruby-3-4" {
  inherits = ["default"]
  context = "images/ruby"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "3.4.Dockerfile"
  tags = ["${IMAGE_REPO}/ruby-3.4:${TAG}"]
}

target "solr-9" {
  inherits = ["default"]
  context = "images/solr"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "9.Dockerfile"
  tags = ["${IMAGE_REPO}/solr-9:${TAG}"]
}

target "solr-9-drupal" {
  inherits = ["default"]
  context = "images/solr-drupal"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons",
    "${IMAGE_REPO}/solr-9": "target:solr-9"
  }
  dockerfile = "9.Dockerfile"
  tags = ["${IMAGE_REPO}/solr-9-drupal:${TAG}"]
}
target "valkey-8" {
  inherits = ["default"]
  context = "images/valkey"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "8.Dockerfile"
  tags = ["${IMAGE_REPO}/valkey-8:${TAG}"]
}

target "valkey-9" {
  inherits = ["default"]
  context = "images/valkey"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "9.Dockerfile"
  tags = ["${IMAGE_REPO}/valkey-9:${TAG}"]
}

target "varnish-6" {
  inherits = ["default"]
  context = "images/varnish"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-6:${TAG}"]
}

target "varnish-6-drupal" {
  inherits = ["default"]
  context = "images/varnish-drupal"
  contexts = {
    "${IMAGE_REPO}/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-6-drupal:${TAG}"]
}

target "varnish-6-persistent" {
  inherits = ["default"]
  context = "images/varnish-persistent"
  contexts = {
    "${IMAGE_REPO}/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-6-persistent:${TAG}"]
}

target "varnish-6-persistent-drupal" {
  inherits = ["default"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "${IMAGE_REPO}/varnish-6-drupal": "target:varnish-6-drupal"
  }
  dockerfile = "6.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-6-persistent-drupal:${TAG}"]
}

target "varnish-7" {
  inherits = ["default"]
  context = "images/varnish"
  contexts = {
    "${IMAGE_REPO}/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-7:${TAG}"]
}

target "varnish-7-drupal" {
  inherits = ["default"]
  context = "images/varnish-drupal"
  contexts = {
    "${IMAGE_REPO}/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-7-drupal:${TAG}"]
}

target "varnish-7-persistent" {
  inherits = ["default"]
  context = "images/varnish-persistent"
  contexts = {
    "${IMAGE_REPO}/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-7-persistent:${TAG}"]
}

target "varnish-7-persistent-drupal" {
  inherits = ["default"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "${IMAGE_REPO}/varnish-7-drupal": "target:varnish-7-drupal"
  }
  dockerfile = "7.Dockerfile"
  tags = ["${IMAGE_REPO}/varnish-7-persistent-drupal:${TAG}"]
}
