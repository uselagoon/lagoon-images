ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/php-8.3-cli:${IMAGE_TAG:-latest}

ENV LAGOON=cli-drupal

COPY drushrc.php drush.yml /home/.drush/

RUN fix-permissions /home/.drush
