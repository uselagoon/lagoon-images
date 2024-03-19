ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-8

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

COPY drupal-4.1.1-solr-8.x-0 /solr-conf

CMD ["solr-precreate", "drupal", "/solr-conf"]
