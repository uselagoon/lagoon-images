ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-7.7

COPY solr7.7 /solr-conf

RUN precreate-core drupal /solr-conf

CMD ["solr-foreground"]
