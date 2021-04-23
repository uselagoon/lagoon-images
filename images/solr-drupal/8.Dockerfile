ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-8

COPY drupal-4.1.1-solr-8.x-0 /solr-conf

RUN precreate-core drupal /solr-conf

CMD ["solr-foreground"]
