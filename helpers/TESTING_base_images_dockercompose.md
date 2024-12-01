docker-compose test all base images
===================================

This is a docker-compose version of the Lando example tests:

Start up tests
--------------

Run the following commands to get up and running with this example.

```bash
# should remove any previous runs and poweroff
sed -i -e "/###/d" *-docker-compose.yml
cp images-docker-compose.yml docker-compose.yml
docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network
docker-compose down

# pull any required images
docker-compose pull || true

# should start up our services successfully
docker-compose build && docker-compose up -d

# Ensure long-running pods are ready to connect
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://php-8-1-dev:9000 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://php-8-2-dev:9000 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://php-8-3-dev:9000 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://php-8-4-dev:9000 -timeout 1m

```

Verification commands
---------------------

Run the following commands to validate things are rolling as they should.

```bash
# should have all the services we expect
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep commons
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep node-18
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep node-20
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep node-22
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-1-dev
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-1-prod
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-2-dev
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-2-prod
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-3-dev
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-3-prod
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-4-dev
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep php-8-4-prod
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep python-3-9
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep python-3-10
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep python-3-11
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep python-3-12
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep python-3-13
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep ruby-3-1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep ruby-3-2
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep ruby-3-3

# commons should be running Alpine Linux
docker compose exec -T commons sh -c "cat /etc/os-release" | grep "Alpine Linux"

# PHP 8.1 development should have PHP installed
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "PHP Version" | grep "8.1"
docker compose exec -T php-8-1-dev bash -c "php -i" | grep "PHP Version" | grep "8.1"

# PHP 8.1 development should have modules enabled
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "APCu Support" | grep "Enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "LibYAML Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "Redis Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "imagick module" | grep "enabled"

# PHP 8.1 development should have default configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "memory_limit" | grep "400M"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "short_open_tag" | grep "On"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "max_execution_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "max_input_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "post_max_size" | grep "2048M"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "max_input_vars" | grep "2000"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "max_file_uploads" | grep "20"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "session.cookie_samesite" | grep "no value"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "display_errors" | grep "Off"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "date.timezone" | grep "UTC"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "opcache.memory_consumption" | grep "256"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "error_reporting" | grep "22527"
docker compose exec -T php-8-1-dev bash -c "php -i" | grep "sendmail_path" | grep "/usr/sbin/sendmail -t -i"

# PHP 8.1 development should have extensions enabled.
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "xdebug.client_port" | grep "9003"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "PHP_IDE_CONFIG" | grep "serverName=lagoon"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "xdebug.log" | grep "/tmp/xdebug.log"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "newrelic.appname" | grep "noproject-nobranch"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "newrelic.logfile" | grep "/dev/stderr"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "newrelic.application_logging.forwarding.enabled" | grep "disabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "Blackfire" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-dev:9000" | grep "blackfire.agent_socket" | grep "tcp://127.0.0.1:8307"

# PHP 8.1 production should have overridden configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-1-prod:9000" | grep "max_input_vars" | grep "4000"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-prod:9000" | grep "max_file_uploads" | grep "40"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-prod:9000" | grep "session.cookie_samesite" | grep "Strict"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-prod:9000" | grep "upload_max_filesize" | grep "1024M"
docker compose exec -T commons sh -c "curl -kL http://php-8-1-prod:9000" | grep "error_reporting" | grep "22519"

# PHP 8.2 development should have PHP installed
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "PHP Version" | grep "8.2"
docker compose exec -T php-8-2-dev bash -c "php -i" | grep "PHP Version" | grep "8.2"

# PHP 8.2 development should have modules enabled
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "APCu Support" | grep "Enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "LibYAML Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "Redis Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "imagick module" | grep "enabled"

# PHP 8.2 development should have default configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "memory_limit" | grep "400M"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "short_open_tag" | grep "On"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "max_execution_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "max_input_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "post_max_size" | grep "2048M"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "max_input_vars" | grep "2000"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "max_file_uploads" | grep "20"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "session.cookie_samesite" | grep "no value"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "display_errors" | grep "Off"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "date.timezone" | grep "UTC"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "opcache.memory_consumption" | grep "256"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "error_reporting" | grep "22527"
docker compose exec -T php-8-2-dev bash -c "php -i" | grep "sendmail_path" | grep "/usr/sbin/sendmail -t -i"

# PHP 8.2 development should have extensions enabled.
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "xdebug.client_port" | grep "9003"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "PHP_IDE_CONFIG" | grep "serverName=lagoon"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "xdebug.log" | grep "/tmp/xdebug.log"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "newrelic.appname" | grep "noproject-nobranch"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "newrelic.application_logging.enabled" | grep "disabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "newrelic.logfile" | grep "/dev/stderr"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "Blackfire" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-dev:9000" | grep "blackfire.agent_socket" | grep "tcp://127.0.0.1:8307"

# PHP 8.2 production should have overridden configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-2-prod:9000" | grep "max_input_vars" | grep "4000"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-prod:9000" | grep "max_file_uploads" | grep "40"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-prod:9000" | grep "session.cookie_samesite" | grep "Strict"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-prod:9000" | grep "upload_max_filesize" | grep "1024M"
docker compose exec -T commons sh -c "curl -kL http://php-8-2-prod:9000" | grep "error_reporting" | grep "22519"

# PHP 8.3 development should have PHP installed
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "PHP Version" | grep "8.3"
docker compose exec -T php-8-3-dev bash -c "php -i" | grep "PHP Version" | grep "8.3"

# PHP 8.3 development should have modules enabled
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "APCu Support" | grep "Enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "LibYAML Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "Redis Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "imagick module" | grep "enabled"

# PHP 8.3 development should have default configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "memory_limit" | grep "400M"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "short_open_tag" | grep "On"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "max_execution_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "max_input_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "post_max_size" | grep "2048M"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "max_input_vars" | grep "2000"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "max_file_uploads" | grep "20"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "session.cookie_samesite" | grep "no value"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "display_errors" | grep "Off"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "date.timezone" | grep "UTC"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "opcache.memory_consumption" | grep "256"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "error_reporting" | grep "22527"
docker compose exec -T php-8-3-dev bash -c "php -i" | grep "sendmail_path" | grep "/usr/sbin/sendmail -t -i"

# PHP 8.3 development should have extensions enabled.
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "xdebug.client_port" | grep "9003"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "PHP_IDE_CONFIG" | grep "serverName=lagoon"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "xdebug.log" | grep "/tmp/xdebug.log"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "newrelic.appname" | grep "noproject-nobranch"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "newrelic.application_logging.enabled" | grep "disabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "newrelic.logfile" | grep "/dev/stderr"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "Blackfire" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-dev:9000" | grep "blackfire.agent_socket" | grep "tcp://127.0.0.1:8307"

# PHP 8.3 production should have overridden configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-3-prod:9000" | grep "max_input_vars" | grep "4000"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-prod:9000" | grep "max_file_uploads" | grep "40"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-prod:9000" | grep "session.cookie_samesite" | grep "Strict"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-prod:9000" | grep "upload_max_filesize" | grep "1024M"
docker compose exec -T commons sh -c "curl -kL http://php-8-3-prod:9000" | grep "error_reporting" | grep "22519"

# PHP 8.4 development should have PHP installed
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "PHP Version" | grep "8.4"
docker compose exec -T php-8-4-dev bash -c "php -i" | grep "PHP Version" | grep "8.4"

# PHP 8.4 development should have modules enabled
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "APCu Support" | grep "Enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "LibYAML Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "Redis Support" | grep "enabled"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "imagick module" | grep "enabled"

# PHP 8.4 development should have default configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "memory_limit" | grep "400M"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "short_open_tag" | grep "On"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "max_execution_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "max_input_time" | grep "900"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "post_max_size" | grep "2048M"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "max_input_vars" | grep "2000"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "max_file_uploads" | grep "20"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "session.cookie_samesite" | grep "no value"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "display_errors" | grep "Off"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "date.timezone" | grep "UTC"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "opcache.memory_consumption" | grep "256"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "error_reporting" | grep "22527"
docker compose exec -T php-8-4-dev bash -c "php -i" | grep "sendmail_path" | grep "/usr/sbin/sendmail -t -i"

# PHP 8.4 development should have extensions enabled.
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "xdebug.client_port" | grep "9003"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "PHP_IDE_CONFIG" | grep "serverName=lagoon"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "xdebug.log" | grep "/tmp/xdebug.log"
# docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "newrelic.appname" | grep "noproject-nobranch"
# docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "newrelic.application_logging.enabled" | grep "disabled"
# docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "newrelic.logfile" | grep "/dev/stderr"
# docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "Blackfire" | grep "enabled"
# docker compose exec -T commons sh -c "curl -kL http://php-8-4-dev:9000" | grep "blackfire.agent_socket" | grep "tcp://127.0.0.1:8307"

# PHP 8.4 production should have overridden configuration.
docker compose exec -T commons sh -c "curl -kL http://php-8-4-prod:9000" | grep "max_input_vars" | grep "4000"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-prod:9000" | grep "max_file_uploads" | grep "40"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-prod:9000" | grep "session.cookie_samesite" | grep "Strict"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-prod:9000" | grep "upload_max_filesize" | grep "1024M"
docker compose exec -T commons sh -c "curl -kL http://php-8-4-prod:9000" | grep "error_reporting" | grep "22519"

# python-3-9 should be version 3.9
docker compose exec -T python-3-9 sh -c "python -V" | grep "3.9"

# python-3-9 should have basic tools installed
docker compose exec -T python-3-9 sh -c "pip list --no-cache-dir" | grep "pip"
docker compose exec -T python-3-9 sh -c "pip list --no-cache-dir" | grep "setuptools"
docker compose exec -T python-3-9 sh -c "pip list --no-cache-dir" | grep "virtualenv"

# python-3-9 should be serving content
docker compose exec -T commons sh -c "curl python-3-9:3000/tmp/test" | grep "Python 3.9"

# python-3-10 should be version 3.10
docker compose exec -T python-3-10 sh -c "python -V" | grep "3.10"

# python-3-10 should have basic tools installed
docker compose exec -T python-3-10 sh -c "pip list --no-cache-dir" | grep "pip"
docker compose exec -T python-3-10 sh -c "pip list --no-cache-dir" | grep "setuptools"
docker compose exec -T python-3-10 sh -c "pip list --no-cache-dir" | grep "virtualenv"

# python-3-10 should be serving content
docker compose exec -T commons sh -c "curl python-3-10:3000/tmp/test" | grep "Python 3.10"

# python-3-11 should be version 3.11
docker compose exec -T python-3-11 sh -c "python -V" | grep "3.11"

# python-3-11 should have basic tools installed
docker compose exec -T python-3-11 sh -c "pip list --no-cache-dir" | grep "pip"
docker compose exec -T python-3-11 sh -c "pip list --no-cache-dir" | grep "setuptools"
docker compose exec -T python-3-11 sh -c "pip list --no-cache-dir" | grep "virtualenv"

# python-3-11 should be serving content
docker compose exec -T commons sh -c "curl python-3-11:3000/tmp/test" | grep "Python 3.11"

# python-3-12 should be version 3.12
docker compose exec -T python-3-12 sh -c "python -V" | grep "3.12"

# python-3-12 should have basic tools installed
docker compose exec -T python-3-12 sh -c "pip list --no-cache-dir" | grep "pip"
docker compose exec -T python-3-12 sh -c "pip list --no-cache-dir" | grep "virtualenv"

# python-3-12 should be serving content
docker compose exec -T commons sh -c "curl python-3-12:3000/tmp/test" | grep "Python 3.12"

# python-3-13 should be version 3.13
docker compose exec -T python-3-13 sh -c "python -V" | grep "3.13"

# python-3-13 should have basic tools installed
docker compose exec -T python-3-13 sh -c "pip list --no-cache-dir" | grep "pip"
docker compose exec -T python-3-13 sh -c "pip list --no-cache-dir" | grep "virtualenv"

# python-3-13 should be serving content
docker compose exec -T commons sh -c "curl python-3-13:3000/tmp/test" | grep "Python 3.13"

# node-18 should have Node 18
docker compose exec -T node-18 sh -c "node -v" | grep "v18"

# node-18 should be serving content
docker compose exec -T commons sh -c "curl node-18:3000/test" | grep "v18"

# node-20 should have Node 20
docker compose exec -T node-20 sh -c "node -v" | grep "v20"

# node-20 should be serving content
docker compose exec -T commons sh -c "curl node-20:3000/test" | grep "v20"

# node-22 should have Node 22
docker compose exec -T node-22 sh -c "node -v" | grep "v22"

# node-22 should be serving content
docker compose exec -T commons sh -c "curl node-22:3000/test" | grep "v22"

# ruby-3-1 should have Ruby 3.1
docker compose exec -T ruby-3-1 sh -c "ruby -v" | grep "3.1"

# ruby-3-1 should be serving content
docker compose exec -T commons sh -c "curl ruby-3-1:3000/tmp/" | grep "ruby 3.1"

# ruby-3-2 should have Ruby 3.2
docker compose exec -T ruby-3-2 sh -c "ruby -v" | grep "3.2"

# ruby-3-2 should be serving content
docker compose exec -T commons sh -c "curl ruby-3-2:3000/tmp/" | grep "ruby 3.2"

# ruby-3-3 should have Ruby 3.3
docker compose exec -T ruby-3-3 sh -c "ruby -v" | grep "3.3"

# ruby-3-3 should be serving content
docker compose exec -T commons sh -c "curl ruby-3-3:3000/tmp/" | grep "ruby 3.3"
```

Destroy tests
-------------

Run the following commands to trash this app like nothing ever happened.

```bash
# should be able to destroy our services with success
docker-compose down --volumes --remove-orphans
rm docker-compose.yml
```
