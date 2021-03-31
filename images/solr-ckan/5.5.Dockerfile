ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-5.5

LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source=https://github.com/uselagoon/lagoon-images

COPY solr5.5 /solr-conf

RUN precreate-core ckan /solr-conf

CMD ["solr-foreground"]
