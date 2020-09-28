ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons

FROM composer:latest as healthcheckbuilder

RUN composer create-project --no-dev amazeeio/healthz-php /healthz-php v0.0.3

FROM php:8.0.0beta4-fpm-alpine3.12

LABEL maintainer="amazee.io"
ENV LAGOON=php

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/
COPY --from=commons /sbin/tini /sbin/
COPY --from=commons /home /home

# Copy healthcheck files

COPY --from=healthcheckbuilder /healthz-php /healthz-php

RUN chmod g+w /etc/passwd \
    && mkdir -p /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

COPY check_fcgi /usr/sbin/
COPY entrypoints/70-php-config.sh entrypoints/60-php-xdebug.sh entrypoints/50-ssmtp.sh entrypoints/71-php-newrelic.sh /lagoon/entrypoints/

COPY php.ini /usr/local/etc/php/
COPY 00-lagoon-php.ini.tpl /usr/local/etc/php/conf.d/
COPY php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf

# New Relic PHP Agent.
# @see https://docs.newrelic.com/docs/release-notes/agent-release-notes/php-release-notes/
# @see https://docs.newrelic.com/docs/agents/php-agent/getting-started/php-agent-compatibility-requirements
ENV NEWRELIC_VERSION=9.13.0.270

RUN apk add --no-cache curl --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/

RUN apk add --no-cache fcgi \
        ssmtp \
        libzip libzip-dev \
        # for gd
        libpng-dev \
        libjpeg-turbo-dev \
        # for gettext
        gettext-dev \
        # for mcrypt
        libmcrypt-dev \
        # for soap
        libxml2-dev \
        # for xsl
        libxslt-dev \
        libgcrypt-dev \
        # for webp
        libwebp-dev \
        postgresql-dev \
        # for yaml
        yaml-dev \
        # for imagemagick
        imagemagick \
        imagemagick-libs \
        imagemagick-dev \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && docker-php-ext-configure gd --with-webp --with-jpeg \
    && docker-php-ext-install -j4 bcmath gd gettext pdo_mysql mysqli pdo_pgsql pgsql shmop soap sockets opcache xsl zip \
# Using a version of pickle.phar built from v0.6.0-18-g9c9e184
    && wget -O /usr/local/bin/pickle "https://github.com/tobybellwood/SampleFiles/raw/master/pickle.phar" \
    && chmod +x /usr/local/bin/pickle
RUN pickle install -n apcu \
    && docker-php-ext-enable apcu 
# RUN pickle install -n xdebug \  ## released PECL xdebug not PHP8 compatible at 2.9.7
#     && docker-php-ext-enable xdebug 
RUN curl -L https://api.github.com/repos/xdebug/xdebug/tarball > /tmp/xdebug.tar.gz \
    && tar xzvf /tmp/xdebug.tar.gz -C /tmp \
    && cd /tmp/xdebug-xdebug* \
    && pickle install -n --version-override=2.9.99 \
    && docker-php-ext-enable xdebug
RUN pickle install -n yaml --version-override=2.2.99 \
    && docker-php-ext-enable yaml 
# RUN curl -L https://api.github.com/repos/php/pecl-file_formats-yaml/tarball > /tmp/yaml.tar.gz \
#     && tar xzvf /tmp/yaml.tar.gz -C /tmp \
#     && cd /tmp/php-pecl-file_formats-yaml* \
#     && pickle install --version-override="2.2.99" \
#     && docker-php-ext-enable yaml
# RUN pickle install -n redis \ ## released PECL redis not PHP8 compatible at 5.3.1
#     && docker-php-ext-enable redis
RUN curl -L https://api.github.com/repos/phpredis/phpredis/tarball > /tmp/phpredis.tar.gz \
    && tar xzvf /tmp/phpredis.tar.gz -C /tmp \
    && cd /tmp/phpredis-phpredis* \
    && pickle install -n --version-override=5.3.99 \
    && docker-php-ext-enable redis
# RUN pickle install -n imagick \ ## released PECL imagick not PHP8 compatible at 3.4.4
#    && docker-php-ext-enable imagick
RUN curl -L https://api.github.com/repos/imagick/imagick/tarball > /tmp/imagick.tar.gz \
    && tar xzvf /tmp/imagick.tar.gz -C /tmp \
    && cd /tmp/Imagick-imagick* \
    && pickle install -n --version-override=3.4.99 \
    && docker-php-ext-enable imagick
# Legacy PECL installs
    # && yes '' | pecl install -f apcu \
    # && yes '' | pecl install -f xdebug \
    # && yes '' | pecl install -f yaml \
    # && yes '' | pecl install -f redis-4.3.0 \
    # && yes '' | pecl install -f imagick \
    # && docker-php-ext-enable apcu redis xdebug imagick \
# RUN sed -i '1s/^/;Intentionally disabled. Enable via setting env variable XDEBUG_ENABLE to true\n;/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
RUN rm -rf /var/cache/apk/* /tmp/pear/ \
    && apk del .phpize-deps \
    # && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini \
    # NewRelic not PHP8 compatible yet
    # && mkdir -p /tmp/newrelic && cd /tmp/newrelic \
    # && wget https://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz \
    # && gzip -dc newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz | tar --strip-components=1 -xf - \
    # && NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 ./newrelic-install install \
    # && sed -i -e "s/newrelic.appname = .*/newrelic.appname = \"\${LAGOON_PROJECT:-noproject}-\${LAGOON_GIT_SAFE_BRANCH:-nobranch}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && sed -i -e "s/;newrelic.enabled = .*/newrelic.enabled = \${NEWRELIC_ENABLED:-false}/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && sed -i -e "s/;newrelic.browser_monitoring.auto_instrument = .*/newrelic.browser_monitoring.auto_instrument = \${NEWRELIC_BROWSER_MONITORING_ENABLED:-true}/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && sed -i -e "s/newrelic.license = .*/newrelic.license = \"\${NEWRELIC_LICENSE:-}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && sed -i -e "s/;newrelic.loglevel = .*/newrelic.loglevel = \"\${NEWRELIC_LOG_LEVEL:-warning}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && sed -i -e "s/;newrelic.daemon.loglevel = .*/newrelic.daemon.loglevel = \"\${NEWRELIC_DAEMON_LOG_LEVEL:-warning}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && sed -i -e "s/newrelic.logfile = .*/newrelic.logfile = \"\/dev\/stdout\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && sed -i -e "s/newrelic.daemon.logfile = .*/newrelic.daemon.logfile = \"\/dev\/stdout\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    # && mv /usr/local/etc/php/conf.d/newrelic.ini /usr/local/etc/php/conf.d/newrelic.disable \
    # && cd / && rm -rf /tmp/newrelic \
    && mkdir -p /app \
    && fix-permissions /usr/local/etc/ \
    && fix-permissions /app \
    && fix-permissions /etc/ssmtp/ssmtp.conf

EXPOSE 9000

ENV AMAZEEIO_DB_HOST=mariadb \
    AMAZEEIO_DB_PORT=3306 \
    AMAZEEIO_DB_USERNAME=drupal \
    AMAZEEIO_DB_PASSWORD=drupal \
    AMAZEEIO_SITENAME=drupal \
    AMAZEEIO_SITE_NAME=drupal \
    AMAZEEIO_SITE_ENVIRONMENT=development \
    AMAZEEIO_HASH_SALT=0000000000000000000000000 \
    AMAZEEIO_TMP_PATH=/tmp \
    AMAZEEIO_LOCATION=docker

ENV LAGOON_ENVIRONMENT_TYPE=development

WORKDIR /app

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/usr/local/sbin/php-fpm", "-F", "-R"]
