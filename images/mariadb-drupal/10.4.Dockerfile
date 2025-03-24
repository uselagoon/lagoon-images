ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/mariadb-10.4

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/mariadb-drupal/10.4.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="MariaDB 10.4 image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/mariadb-10.4-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/mariadb-10.4"

LABEL sh.lagoon.image.deprecated.status="endoflife"
LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/mariadb-10.11-drupal"

ENV MARIADB_DATABASE=drupal \
    MARIADB_USER=drupal \
    MARIADB_PASSWORD=drupal
