ARG UPSTREAM_REPO
ARG UPSTREAM_TAG
FROM ${UPSTREAM_REPO:-lagoon}/php-8.3-cli:${UPSTREAM_TAG:-latest}

ENV LAGOON=cli-drupal

COPY drushrc.php drush.yml /home/.drush/

RUN fix-permissions /home/.drush
