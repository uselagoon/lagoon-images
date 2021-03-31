ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-7.7

LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source=https://github.com/uselagoon/lagoon-images

COPY solr7.7 /solr-conf

RUN precreate-core drupal /solr-conf

CMD ["solr-foreground"]
