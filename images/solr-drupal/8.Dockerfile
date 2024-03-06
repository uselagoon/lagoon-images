ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/solr-8:${IMAGE_TAG:-latest}

COPY drupal-4.1.1-solr-8.x-0 /solr-conf

CMD ["solr-precreate", "drupal", "/solr-conf"]
