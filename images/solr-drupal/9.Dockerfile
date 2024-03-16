ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-9

COPY drupal-4.1.1-solr-8.x-0 /solr-conf

CMD ["solr-precreate", "drupal", "/solr-conf"]
