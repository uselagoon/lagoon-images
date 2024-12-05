ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/php-8.4-fpm

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/php-cli/8.4.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="PHP 8.4 cli image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/php-8.4-cli"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/php-8.4-fpm"

ENV LAGOON=cli

STOPSIGNAL SIGTERM

RUN apk add -U --repository http://dl-cdn.alpinelinux.org/alpine/v3.19/main mariadb-client=10.11.6-r0 mariadb-connector-c \
    && apk add --no-cache bash \
        coreutils \
        findutils \
        git \
        gzip  \
        mongodb-tools \
        nodejs=~20 \
        npm \
        openssh-client \
        openssh-sftp-server \
        patch \
        postgresql-client \
        procps \
        rsync \
        unzip \
        yarn \
    && ln -s /usr/lib/ssh/sftp-server /usr/local/bin/sftp-server \
    && rm -rf /var/cache/apk/*

RUN curl -L -o /usr/local/bin/composer https://github.com/composer/composer/releases/download/2.8.3/composer.phar \
    && chmod +x /usr/local/bin/composer \
    && mkdir -p /home/.ssh \
    && fix-permissions /home/

# Adding Composer vendor bin directories to $PATH.
ENV PATH="$PATH:/app/vendor/bin:/home/.composer/vendor/bin"
# We not only use "export $PATH" as this could be overwritten again
# like it happens in /etc/profile of alpine Images.

COPY entrypoints /lagoon/entrypoints/

# Remove warning about running as root in composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Making sure the path is not only added during entrypoint, but also when creating a new shell
RUN echo "source /lagoon/entrypoints/90-composer-path.sh" >> /home/.bashrc
# Make sure shells are not running forever
RUN echo "source /lagoon/entrypoints/80-shell-timeout.sh" >> /home/.bashrc
# Make sure xdebug is automatically enabled also for cli scripts
RUN echo "source /lagoon/entrypoints/61-php-xdebug-cli-env.sh" >> /home/.bashrc
# helper functions
RUN echo "source /lagoon/entrypoints/55-cli-helpers.sh" >> /home/.bashrc

# Copy mariadb-client configuration.
COPY mariadb-client.cnf /etc/my.cnf.d/
RUN fix-permissions /etc/my.cnf.d/

# SSH Key and Agent Setup
COPY ssh_config /etc/ssh/ssh_config
COPY id_ed25519_lagoon_cli.key /home/.ssh/lagoon_cli.key
RUN chmod 400 /home/.ssh/lagoon_cli.key
ENV SSH_AUTH_SOCK=/tmp/ssh-agent

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/bin/docker-sleep"]
