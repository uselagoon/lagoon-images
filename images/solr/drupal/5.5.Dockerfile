ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-5.5

COPY solr5.5 /solr-conf

RUN precreate-core drupal /solr-conf

CMD ["solr-foreground"]
