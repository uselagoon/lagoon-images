ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/php-8.3-cli

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=cli-drupal

COPY drushrc.php drush.yml /home/.drush/

RUN fix-permissions /home/.drush
