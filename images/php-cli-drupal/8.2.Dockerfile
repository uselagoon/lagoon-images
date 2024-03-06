ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/php-8.2-cli:${IMAGE_TAG:-latest}

ENV LAGOON=cli-drupal

ENV DRUSH_LAUNCHER_FALLBACK=/opt/drush8/vendor/bin/drush

RUN curl -L -o /usr/local/bin/drupal "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/1.9.7/drupal.phar" \
    && chmod +x /usr/local/bin/drupal

RUN mkdir -p /opt/drush8 \
    && php /usr/local/bin/composer init -n -d /opt/drush8 --require=drush/drush:8.4.12 \
    && php -d memory_limit=-1 /usr/local/bin/composer update -n -d /opt/drush8 \
    && php /usr/local/bin/composer clear-cache

RUN curl -L -o /usr/local/bin/drush "https://github.com/drush-ops/drush-launcher/releases/download/0.10.2/drush.phar" \
    && chmod +x /usr/local/bin/drush \
    && mkdir -p /home/.drush

COPY drushrc.php drush.yml /home/.drush/

RUN fix-permissions /home/.drush
