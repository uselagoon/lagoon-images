ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-8

COPY 8.x /solr-conf

RUN precreate-core drupal /solr-conf

CMD ["solr-foreground"]
