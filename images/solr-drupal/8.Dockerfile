ARG UPSTREAM_REPO
ARG UPSTREAM_TAG
FROM ${UPSTREAM_REPO:-lagoon}/solr-8:${UPSTREAM_TAG:-latest}

COPY drupal-4.1.1-solr-8.x-0 /solr-conf

CMD ["solr-precreate", "drupal", "/solr-conf"]
