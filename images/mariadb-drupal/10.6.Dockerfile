ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/mariadb-10.6

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/mariadb-drupal/10.6.Dockerfile"
LABEL org.opencontainers.image.description="MariaDB 10.6 image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/mariadb-10.6-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/mariadb-10.6"

ENV MARIADB_DATABASE=drupal \
    MARIADB_USER=drupal \
    MARIADB_PASSWORD=drupal
