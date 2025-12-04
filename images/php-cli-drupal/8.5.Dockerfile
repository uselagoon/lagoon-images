ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/php-8.5-cli

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/php-cli-drupal/8.5.Dockerfile"
LABEL org.opencontainers.image.description="PHP 8.5 cli image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/php-8.5-cli-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/php-8.5-cli"

ENV LAGOON=cli-drupal

COPY drushrc.php drush.yml /home/.drush/

RUN fix-permissions /home/.drush
