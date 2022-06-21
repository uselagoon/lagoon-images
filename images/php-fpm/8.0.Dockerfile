ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons

FROM composer:latest as healthcheckbuilder

RUN composer create-project --no-dev amazeeio/healthz-php /healthz-php v0.0.6

FROM php:8.0.20-fpm-alpine3.16

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=php

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

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

COPY php.ini /usr/local/etc/php/
COPY 00-lagoon-php.ini.tpl /usr/local/etc/php/conf.d/
COPY php-fpm.d/www.conf php-fpm.d/global.conf /usr/local/etc/php-fpm.d/
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
COPY blackfire.ini /usr/local/etc/php/conf.d/blackfire.disable

RUN apk add --no-cache --virtual .devdeps \
        libzip-dev \
        # for gd
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
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
        imagemagick-dev \
        && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
        && yes '' | pecl install -f apcu-5.1.21 \
        && yes '' | pecl install -f imagick-3.7.0 \
        && yes '' | pecl install -f redis-5.3.7 \
        && yes '' | pecl install -f xdebug-3.1.5 \
        && yes '' | pecl install -f yaml-2.2.2 \
        && docker-php-ext-enable apcu imagick redis xdebug yaml \
        && rm -rf /tmp/pear \
        && apk del -r .phpize-deps \
        && sed -i '1s/^/;Intentionally disabled. Enable via setting env variable XDEBUG_ENABLE to true\n;/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
        && docker-php-ext-configure gd --with-webp --with-jpeg --with-freetype \
        && docker-php-ext-install -j4 bcmath gd gettext mysqli pdo_mysql opcache pdo_pgsql pgsql shmop soap sockets xsl zip \
        && apk del -r .devdeps \
        && apk add --no-cache \
        fcgi \
        ssmtp \
        libzip \
        libpng \
        libjpeg-turbo \
        gettext \
        libmcrypt \
        libxml2 \
        libxslt \
        libgcrypt \
        libwebp \
        postgresql-libs \
        yaml \
        imagemagick \
        imagemagick-libs


# New Relic PHP Agent.
# @see https://docs.newrelic.com/docs/release-notes/agent-release-notes/php-release-notes/
# @see https://docs.newrelic.com/docs/agents/php-agent/getting-started/php-agent-compatibility-requirements
ENV NEWRELIC_VERSION=9.20.0.310
RUN mkdir -p /tmp/newrelic && cd /tmp/newrelic \
    && wget https://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz \
    && gzip -dc newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz | tar --strip-components=1 -xf - \
    && NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 ./newrelic-install install \
    && sed -i -e "s/newrelic.appname = .*/newrelic.appname = \"\${LAGOON_PROJECT:-noproject}-\${LAGOON_GIT_SAFE_BRANCH:-nobranch}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.enabled = .*/newrelic.enabled = \${NEWRELIC_ENABLED:-false}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.browser_monitoring.auto_instrument = .*/newrelic.browser_monitoring.auto_instrument = \${NEWRELIC_BROWSER_MONITORING_ENABLED:-true}/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/newrelic.license = .*/newrelic.license = \"\${NEWRELIC_LICENSE:-}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.loglevel = .*/newrelic.loglevel = \"\${NEWRELIC_LOG_LEVEL:-warning}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/;newrelic.daemon.loglevel = .*/newrelic.daemon.loglevel = \"\${NEWRELIC_DAEMON_LOG_LEVEL:-warning}\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/newrelic.logfile = .*/newrelic.logfile = \"\/dev\/stderr\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && sed -i -e "s/newrelic.daemon.logfile = .*/newrelic.daemon.logfile = \"\/dev\/stderr\"/" /usr/local/etc/php/conf.d/newrelic.ini \
    && mv /usr/local/etc/php/conf.d/newrelic.ini /usr/local/etc/php/conf.d/newrelic.disable \
    && cd / && rm -rf /tmp/newrelic \
    && fix-permissions /usr/local/etc/

# Add blackfire probe and agent.
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && mkdir -p /blackfire \
    && curl -A "Docker" -o /blackfire/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && tar zxpf /blackfire/blackfire-probe.tar.gz -C /blackfire \
    && mv /blackfire/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && fix-permissions /usr/local/etc/php/conf.d/

ENV BLACKFIRE_VERSION=2.7.1
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
