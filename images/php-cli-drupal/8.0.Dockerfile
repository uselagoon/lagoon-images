ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/php-8.0-cli

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=cli-drupal
ENV MARIADB_MAX_ALLOWED_PACKET=64M

# Defining Versions - https://github.com/hechoendrupal/drupal-console-launcher/releases
ENV DRUPAL_CONSOLE_LAUNCHER_VERSION=1.9.7 \
    DRUPAL_CONSOLE_LAUNCHER_SHA=fe83050489c66a0578eb59d6744420be6fd4c5d1 \
    DRUSH_VERSION=8.4.10 \
    DRUSH_LAUNCHER_VERSION=0.10.1 \
    DRUSH_LAUNCHER_FALLBACK=/opt/drush8/vendor/bin/drush

RUN curl -L -o /usr/local/bin/drupal "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VERSION}/drupal.phar" \
    && echo "${DRUPAL_CONSOLE_LAUNCHER_SHA} /usr/local/bin/drupal" | sha1sum -c - \
    && chmod +x /usr/local/bin/drupal \
    && mkdir -p /opt/drush8 \
    && php /usr/local/bin/composer init -n -d /opt/drush8 --require=drush/drush:${DRUSH_VERSION} \
    && php -d memory_limit=-1 /usr/local/bin/composer update -n -d /opt/drush8 \
    && wget -O /usr/local/bin/drush "https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar" \
    && chmod +x /usr/local/bin/drush \
    && mkdir -p /home/.drush

COPY drushrc.php drush.yml /home/.drush/

RUN fix-permissions /home/.drush
