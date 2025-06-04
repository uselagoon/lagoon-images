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
    "rabbitmq",
    "rabbitmq-cluster",
    "redis-6",
    "redis-6-persistent",
    "redis-7",
    "redis-7-persistent",
    "redis-8",
    "ruby-3-2",
    "ruby-3-3",
    "ruby-3-4",
    "solr-8",
    "solr-8-drupal",
    "solr-9",
    "solr-9-drupal",
    "valkey-8",
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
    "node-18",
    "node-18-builder",
    "node-18-cli",
    "node-20",
    "node-20-builder",
    "node-20-cli",
    "node-22",
    "node-22-builder",
    "node-22-cli",
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
    "redis-6",
    "redis-6-persistent",
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
    "solr-8",
    "solr-8-drupal",
    "solr-9",
    "solr-9-drupal",
  ]
}

group "valkey" {
  targets = [
    "commons", 
    "valkey-8"
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
  context = "images/commons"
  dockerfile = "Dockerfile"
  tags = ["ghcr.io/tobybellwood/commons:bake"]
  platforms = ["linux/amd64","linux/arm64"]
}

target "mariadb-10-6" {
  inherits = ["commons"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mariadb-10.6:bake"]
}

target "mariadb-10-6-drupal" {
  inherits = ["commons"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.6": "target:mariadb-10-6"
  }
  dockerfile = "10.6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mariadb-10.6-drupal:bake"]
}

target "mariadb-10-11" {
  inherits = ["commons"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "10.11.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mariadb-10.11:bake"]
}

target "mariadb-10-11-drupal" {
  inherits = ["commons"]
  context = "images/mariadb-drupal"
  contexts = {
    "lagoon/mariadb-10.11": "target:mariadb-10-6"
  }
  dockerfile = "10.11.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mariadb-10.11-drupal:bake"]
}

target "mariadb-11-4" {
  inherits = ["commons"]
  context = "images/mariadb"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "11.4.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mariadb-11.4:bake"]
}


target "mongo-4" {
  inherits = ["commons"]
  context = "images/mongo"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "4.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mongo-4:bake"]
}

target "mysql-8-0" {
  inherits = ["commons"]
  context = "images/mysql"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.0.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mysql-8.0:bake"]
}

target "mysql-8-4" {
  inherits = ["commons"]
  context = "images/mysql"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["ghcr.io/tobybellwood/mysql-8.4:bake"]
}

target "nginx" {
  inherits = ["commons"]
  context = "images/nginx"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  tags = ["ghcr.io/tobybellwood/nginx:bake"]
}

target "nginx-drupal" {
  inherits = ["commons"]
  context = "images/nginx-drupal"
  contexts = {
    "lagoon/nginx": "target:nginx"
  }
  dockerfile = "Dockerfile"
  tags = ["ghcr.io/tobybellwood/nginx-drupal:bake"]
}

target "node-18" {
  inherits = ["commons"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "18.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-18:bake"]
}

target "node-18-builder" {
  inherits = ["commons"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-18": "target:node-18"
  }
  dockerfile = "18.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-18-builder:bake"]
}

target "node-18-cli" {
  inherits = ["commons"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-18": "target:node-18"
  }
  dockerfile = "18.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-18-cli:bake"]
}

target "node-20" {
  inherits = ["commons"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "20.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-20:bake"]
}

target "node-20-builder" {
  inherits = ["commons"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-20-builder:bake"]
}

target "node-20-cli" {
  inherits = ["commons"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-20": "target:node-20"
  }
  dockerfile = "20.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-20-cli:bake"]
}

target "node-22" {
  inherits = ["commons"]
  context = "images/node"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "22.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-22:bake"]
}

target "node-22-builder" {
  inherits = ["commons"]
  context = "images/node-builder"
  contexts = {
    "lagoon/node-22": "target:node-22"
  }
  dockerfile = "22.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-22-builder:bake"]
}

target "node-22-cli" {
  inherits = ["commons"]
  context = "images/node-cli"
  contexts = {
    "lagoon/node-22": "target:node-22"
  }
  dockerfile = "22.Dockerfile"
  tags = ["ghcr.io/tobybellwood/node-22-cli:bake"]
}

target "opensearch-2" {
  inherits = ["commons"]
  context = "images/opensearch"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "2.Dockerfile"
  tags = ["ghcr.io/tobybellwood/opensearch-2:bake"]
}

target "opensearch-3" {
  inherits = ["commons"]
  context = "images/opensearch"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.Dockerfile"
  tags = ["ghcr.io/tobybellwood/opensearch-3:bake"]
}

target "php-8-1-fpm" {
  inherits = ["commons"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.1.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.1-fpm:bake"]
}

target "php-8-1-cli" {
  inherits = ["commons"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.1-fpm": "target:php-8-1-fpm"
  }
  dockerfile = "8.1.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.1-cli:bake"]
}

target "php-8-1-cli-drupal" {
  inherits = ["commons"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.1-cli": "target:php-8-1-cli"
  }
  dockerfile = "8.1.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.1-cli-drupal:bake"]
}

target "php-8-2-fpm" {
  inherits = ["commons"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.2.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.2-fpm:bake"]
}

target "php-8-2-cli" {
  inherits = ["commons"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.2-fpm": "target:php-8-2-fpm"
  }
  dockerfile = "8.2.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.2-cli:bake"]
}

target "php-8-2-cli-drupal" {
  inherits = ["commons"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.2-cli": "target:php-8-2-cli"
  }
  dockerfile = "8.2.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.2-cli-drupal:bake"]
}

target "php-8-3-fpm" {
  inherits = ["commons"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.3.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.3-fpm:bake"]
}

target "php-8-3-cli" {
  inherits = ["commons"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.3-fpm": "target:php-8-3-fpm"
  }
  dockerfile = "8.3.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.3-cli:bake"]
}

target "php-8-3-cli-drupal" {
  inherits = ["commons"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.3-cli": "target:php-8-3-cli"
  }
  dockerfile = "8.3.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.3-cli-drupal:bake"]
}

target "php-8-4-fpm" {
  inherits = ["commons"]
  context = "images/php-fpm"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.4-fpm:bake"]
}

target "php-8-4-cli" {
  inherits = ["commons"]
  context = "images/php-cli"
  contexts = {
    "lagoon/php-8.4-fpm": "target:php-8-4-fpm"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.4-cli:bake"]
}

target "php-8-4-cli-drupal" {
  inherits = ["commons"]
  context = "images/php-cli-drupal"
  contexts = {
    "lagoon/php-8.4-cli": "target:php-8-4-cli"
  }
  dockerfile = "8.4.Dockerfile"
  tags = ["ghcr.io/tobybellwood/php-8.4-cli-drupal:bake"]
}

target "postgres-13" {
  inherits = ["commons"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "13.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-13:bake"]
}

target "postgres-13-drupal" {
  inherits = ["commons"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-13": "target:postgres-13"
  }
  dockerfile = "13.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-13-drupal:bake"]
}

target "postgres-14" {
  inherits = ["commons"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "14.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-14:bake"]
}

target "postgres-14-drupal" {
  inherits = ["commons"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-14": "target:postgres-14"
  }
  dockerfile = "14.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-14-drupal:bake"]
}

target "postgres-15" {
  inherits = ["commons"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "15.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-15:bake"]
}

target "postgres-15-drupal" {
  inherits = ["commons"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-15": "target:postgres-15"
  }
  dockerfile = "15.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-15-drupal:bake"]
}

target "postgres-16" {
  inherits = ["commons"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "16.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-16:bake"]
}

target "postgres-16-drupal" {
  inherits = ["commons"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-16": "target:postgres-16"
  }
  dockerfile = "16.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-16-drupal:bake"]
}

target "postgres-17" {
  inherits = ["commons"]
  context = "images/postgres"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "17.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-17:bake"]
}

target "postgres-17-drupal" {
  inherits = ["commons"]
  context = "images/postgres-drupal"
  contexts = {
    "lagoon/postgres-17": "target:postgres-17"
  }
  dockerfile = "17.Dockerfile"
  tags = ["ghcr.io/tobybellwood/postgres-17-drupal:bake"]
}

target "python-3-9" {
  inherits = ["commons"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.9.Dockerfile"
  tags = ["ghcr.io/tobybellwood/python-3.9:bake"]
}

target "python-3-10" {
  inherits = ["commons"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.10.Dockerfile"
  tags = ["ghcr.io/tobybellwood/python-3.10:bake"]
}

target "python-3-11" {
  inherits = ["commons"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.11.Dockerfile"
  tags = ["ghcr.io/tobybellwood/python-3.11:bake"]
}

target "python-3-12" {
  inherits = ["commons"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.12.Dockerfile"
  tags = ["ghcr.io/tobybellwood/python-3.12:bake"]
}

target "python-3-13" {
  inherits = ["commons"]
  context = "images/python"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.13.Dockerfile"
  tags = ["ghcr.io/tobybellwood/python-3.13:bake"]
}

target "rabbitmq" {
  inherits = ["commons"]
  context = "images/rabbitmq"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "Dockerfile"
  tags = ["ghcr.io/tobybellwood/rabbitmq:bake"]
}

target "rabbitmq-cluster" {
  inherits = ["commons"]
  context = "images/rabbitmq-cluster"
  contexts = {
    "lagoon/rabbitmq": "target:rabbitmq"
  }
  dockerfile = "Dockerfile"
  tags = ["ghcr.io/tobybellwood/rabbitmq-cluster:bake"]
}

target "redis-6" {
  inherits = ["commons"]
  context = "images/redis"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/redis-6:bake"]
}

target "redis-6-persistent" {
  inherits = ["commons"]
  context = "images/redis-persistent"
  contexts = {
    "lagoon/redis-6": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/redis-6-persistent:bake"]
}

target "redis-7" {
  inherits = ["commons"]
  context = "images/redis"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  tags = ["ghcr.io/tobybellwood/redis-7:bake"]
}

target "redis-7-persistent" {
  inherits = ["commons"]
  context = "images/redis-persistent"
  contexts = {
    "lagoon/redis-7": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  tags = ["ghcr.io/tobybellwood/redis-7-persistent:bake"]
}

target "redis-8" {
  inherits = ["commons"]
  context = "images/redis"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.Dockerfile"
  tags = ["ghcr.io/tobybellwood/redis-8:bake"]
}

target "ruby-3-2" {
  inherits = ["commons"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.2.Dockerfile"
  tags = ["ghcr.io/tobybellwood/ruby-3.2:bake"]
}

target "ruby-3-3" {
  inherits = ["commons"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.3.Dockerfile"
  tags = ["ghcr.io/tobybellwood/ruby-3.3:bake"]
}

target "ruby-3-4" {
  inherits = ["commons"]
  context = "images/ruby"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "3.4.Dockerfile"
  tags = ["ghcr.io/tobybellwood/ruby-3.4:bake"]
}

target "solr-8" {
  inherits = ["commons"]
  context = "images/solr"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.Dockerfile"
  tags = ["ghcr.io/tobybellwood/solr-8:bake"]
}

target "solr-8-drupal" {
  inherits = ["commons"]
  context = "images/solr-drupal"
  contexts = {
    "lagoon/commons": "target:commons",
    "lagoon/solr-8": "target:solr-8"
  }
  dockerfile = "8.Dockerfile"
  tags = ["ghcr.io/tobybellwood/solr-8-drupal:bake"]
}

target "solr-9" {
  inherits = ["commons"]
  context = "images/solr"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "9.Dockerfile"
  tags = ["ghcr.io/tobybellwood/solr-9:bake"]
}

target "solr-9-drupal" {
  inherits = ["commons"]
  context = "images/solr-drupal"
  contexts = {
    "lagoon/commons": "target:commons",
    "lagoon/solr-9": "target:solr-9"
  }
  dockerfile = "9.Dockerfile"
  tags = ["ghcr.io/tobybellwood/solr-9-drupal:bake"]
}
target "valkey-8" {
  inherits = ["commons"]
  context = "images/valkey"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "8.Dockerfile"
  tags = ["ghcr.io/tobybellwood/valkey-8:bake"]
}

target "varnish-6" {
  inherits = ["commons"]
  context = "images/varnish"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-6:bake"]
}

target "varnish-6-drupal" {
  inherits = ["commons"]
  context = "images/varnish-drupal"
  contexts = {
    "lagoon/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-6-drupal:bake"]
}

target "varnish-6-persistent" {
  inherits = ["commons"]
  context = "images/varnish-persistent"
  contexts = {
    "lagoon/varnish-6": "target:varnish-6"
  }
  dockerfile = "6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-6-persistent:bake"]
}

target "varnish-6-persistent-drupal" {
  inherits = ["commons"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "lagoon/varnish-6-drupal": "target:varnish-6-drupal"
  }
  dockerfile = "6.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-6-persistent-drupal:bake"]
}

target "varnish-7" {
  inherits = ["commons"]
  context = "images/varnish"
  contexts = {
    "lagoon/commons": "target:commons"
  }
  dockerfile = "7.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-7:bake"]
}

target "varnish-7-drupal" {
  inherits = ["commons"]
  context = "images/varnish-drupal"
  contexts = {
    "lagoon/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-7-drupal:bake"]
}

target "varnish-7-persistent" {
  inherits = ["commons"]
  context = "images/varnish-persistent"
  contexts = {
    "lagoon/varnish-7": "target:varnish-7"
  }
  dockerfile = "7.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-7-persistent:bake"]
}

target "varnish-7-persistent-drupal" {
  inherits = ["commons"]
  context = "images/varnish-persistent-drupal"
  contexts = {
    "lagoon/varnish-7-drupal": "target:varnish-7-drupal"
  }
  dockerfile = "7.Dockerfile"
  tags = ["ghcr.io/tobybellwood/varnish-7-persistent-drupal:bake"]
}
