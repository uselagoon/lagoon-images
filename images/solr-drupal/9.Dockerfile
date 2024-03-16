ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-9

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

COPY 9.x /solr-conf/conf

CMD ["solr-precreate", "drupal", "/solr-conf"]
