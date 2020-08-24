ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-6.6

COPY solr6.6 /solr-conf

RUN precreate-core ckan /solr-conf

CMD ["solr-foreground"]
