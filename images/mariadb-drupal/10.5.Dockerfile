ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/mariadb-10.5

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV MARIADB_DATABASE=drupal \
    MARIADB_USER=drupal \
    MARIADB_PASSWORD=drupal
