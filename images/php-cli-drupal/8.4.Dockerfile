ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/php-8.4-cli

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/php-cli-drupal/8.4.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="PHP 8.4 cli image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/php-8.4-cli-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/php-8.4-cli"

ENV LAGOON=cli-drupal

COPY drushrc.php drush.yml /home/.drush/

RUN fix-permissions /home/.drush
