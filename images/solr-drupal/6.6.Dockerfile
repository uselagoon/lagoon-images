ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-6.6

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

COPY solr6.6 /solr-conf

RUN precreate-core drupal /solr-conf

CMD ["solr-foreground"]
