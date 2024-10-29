ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons

FROM composer:latest AS healthcheckbuilder

RUN composer create-project --no-dev amazeeio/healthz-php /healthz-php v0.0.6

FROM php:8.3.13-fpm-alpine3.20

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/php-fpm/8.3.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="PHP 8.3 FPM image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/php-8.3-fpm"
LABEL org.opencontainers.image.base.name="docker.io/php:8.3-fpm-alpine3.20"

ENV LAGOON=php

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /sbin/tini /sbin/
COPY --from=commons /home /home

# Copy healthcheck files
COPY --from=healthcheckbuilder /healthz-php /healthz-php

RUN fix-permissions /etc/passwd \
    && mkdir -p /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

COPY check_fcgi /usr/sbin/
COPY entrypoints /lagoon/entrypoints/

RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY 00-lagoon-php.ini.tpl "$PHP_INI_DIR/conf.d/"
COPY php-fpm.d/www.conf php-fpm.d/global.conf /usr/local/etc/php-fpm.d/
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
COPY blackfire.ini /usr/local/etc/php/conf.d/blackfire.disable

RUN apk update \
    && apk add --no-cache --virtual .devdeps \
        # for gd
        freetype-dev \
        # for gettext
        gettext-dev \
        # for imagemagick
        imagemagick-dev \
        libgcrypt-dev \
        # for gd
        libjpeg-turbo-dev \
        # for mcrypt
        libmcrypt-dev \
        # for gd
        libpng-dev \
        # for webp
        libwebp-dev \
        # for soap
        libxml2-dev \
        # for tidy
        tidyhtml-dev \
        # for xdebug
        linux-headers \
        # for xsl
        libxslt-dev \
        libzip-dev \
        postgresql-dev \
        # for yaml
        yaml-dev \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && yes '' | pecl install -f apcu-5.1.24 \
    # && yes '' | pecl install -f imagick-3.7.0 \ # fix for https://github.com/Imagick/imagick/pull/641
    && yes '' | pecl install -f redis-5.3.7 \
    && yes '' | pecl install -f xdebug-3.3.2 \
    && yes '' | pecl install -f yaml-2.2.4 \
    # fix for https://github.com/Imagick/imagick/pull/641
    && cd /tmp \
    && yes '' | pecl download -Z imagick-3.7.0 \
    && tar -xf imagick-3.7.0.tar imagick-3.7.0/Imagick.stub.php \
    && sed -i '$ i\#endif' imagick-3.7.0/Imagick.stub.php \
    && tar -uvf imagick-3.7.0.tar imagick-3.7.0/Imagick.stub.php \
    && yes '' | pecl install -f /tmp/imagick-3.7.0.tar \
    && docker-php-ext-enable apcu imagick redis xdebug yaml \
    && rm -rf /tmp/imagick* \
    && rm -rf /tmp/pear \
    && cd - \
    && apk del -r \
        .phpize-deps \
    && sed -i '1s/^/;Intentionally disabled. Enable via setting env variable XDEBUG_ENABLE to true\n;/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && docker-php-ext-configure gd --with-webp --with-jpeg --with-freetype \
    && docker-php-ext-install -j4 bcmath exif gd gettext intl mysqli pdo_mysql opcache pdo_pgsql pgsql shmop soap sockets tidy xsl zip \
    && apk del -r \
        .devdeps \
    && apk add --no-cache \
        acl \
        fcgi \
        file \
        gettext \
        icu-libs \
        icu-data-full \
        imagemagick \
        imagemagick-heic \
        imagemagick-libs \
        imagemagick-jpeg \
        imagemagick-jxl \
        imagemagick-pango \
        imagemagick-pdf \
        imagemagick-raw \
        imagemagick-webp \
        imagemagick-svg \
        imagemagick-tiff \
        libgcrypt \
        libjpeg-turbo \
        libmcrypt \
        libpng \
        libwebp \
        libxml2 \
        libxslt \
        libzip \
        postgresql-libs \
        ssmtp \
        tidyhtml \
        unzip \
        yaml \
    && rm -rf /var/cache/apk/*

# New Relic PHP Agent.
# @see https://docs.newrelic.com/docs/release-notes/agent-release-notes/php-release-notes/
# @see https://docs.newrelic.com/docs/agents/php-agent/getting-started/php-agent-compatibility-requirements
ENV NEWRELIC_VERSION=11.3.0.16
RUN mkdir -p /tmp/newrelic && cd /tmp/newrelic \
    && wget https://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz \
    && gzip -dc newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz | tar --strip-components=1 -xf - \
    && mkdir /etc/conf.d && mkdir /etc/init.d \
    && NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 ./newrelic-install install \
    && sed -i -e "s/newrelic.appname = .*/newrelic.appname = \"\${LAGOON_PROJECT:-noproject}-\${LAGOON_GIT_SAFE_BRANCH:-nobranch}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.enabled = .*/newrelic.enabled = \${NEWRELIC_ENABLED:-false}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.browser_monitoring.auto_instrument = .*/newrelic.browser_monitoring.auto_instrument = \${NEWRELIC_BROWSER_MONITORING_ENABLED:-true}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.distributed_tracing_enabled = .*/newrelic.distributed_tracing_enabled = \${NEWRELIC_DISTRIBUTED_TRACING_ENABLED:-false}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/newrelic.license = .*/newrelic.license = \"\${NEWRELIC_LICENSE:-}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.loglevel = .*/newrelic.loglevel = \"\${NEWRELIC_LOG_LEVEL:-warning}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.daemon.loglevel = .*/newrelic.daemon.loglevel = \"\${NEWRELIC_DAEMON_LOG_LEVEL:-warning}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/newrelic.logfile = .*/newrelic.logfile = \"\/dev\/stderr\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/newrelic.daemon.logfile = .*/newrelic.daemon.logfile = \"\/dev\/stderr\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.application_logging.enabled = .*/newrelic.application_logging.enabled = \${NEWRELIC_APPLICATION_LOGGING_ENABLED:-true}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.application_logging.metrics.enabled = .*/newrelic.application_logging.metrics.enabled = \${NEWRELIC_APPLICATION_LOGGING_METRICS_ENABLED:-true}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.application_logging.forwarding.enabled = .*/newrelic.application_logging.forwarding.enabled = \${NEWRELIC_APPLICATION_LOGGING_FORWARDING_ENABLED:-true}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && mv /usr/local/etc/php/conf.d/newrelic.ini /usr/local/etc/php/conf.d/newrelic.disable \
    && cd / && rm -rf /tmp/newrelic \
    && fix-permissions /usr/local/etc/

# Add blackfire probe and agent.
ENV BLACKFIRE_VERSION=2.28.16
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && mkdir -p /blackfire \
    && curl -A "Docker" -o /blackfire/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && tar zxpf /blackfire/blackfire-probe.tar.gz -C /blackfire \
    && mv /blackfire/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && fix-permissions /usr/local/etc/php/conf.d/

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -A "Docker" -o /blackfire/blackfire-linux_${architecture}.tar.gz -D - -L -s https://packages.blackfire.io/binaries/blackfire/${BLACKFIRE_VERSION}/blackfire-linux_${architecture}.tar.gz \
    && tar zxpf /blackfire/blackfire-linux_${architecture}.tar.gz -C /blackfire \
    && mv /blackfire/blackfire /bin/blackfire \
    && chmod +x /bin/blackfire \
    && mkdir -p /etc/blackfire \
    && touch /etc/blackfire/agent \
    && fix-permissions /etc/blackfire/

RUN mkdir -p /app \
    && fix-permissions /app \
    && fix-permissions /etc/ssmtp/ssmtp.conf \
    && fix-permissions /usr/local/etc/

EXPOSE 9000

ENV LAGOON_ENVIRONMENT_TYPE=development

WORKDIR /app

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/usr/local/sbin/php-fpm", "-F", "-R"]
