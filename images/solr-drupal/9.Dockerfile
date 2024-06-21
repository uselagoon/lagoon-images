ARG UPSTREAM_REPO
ARG UPSTREAM_TAG
FROM ${UPSTREAM_REPO:-lagoon}/commons:${UPSTREAM_TAG:-latest} as jumpstart

ADD https://git.drupalcode.org/project/search_api_solr.git#4.3.2 /search_api_solr

ARG UPSTREAM_REPO
ARG UPSTREAM_TAG
FROM ${UPSTREAM_REPO:-lagoon}/solr-8:${UPSTREAM_TAG:-latest}

COPY --from=jumpstart /search_api_solr/jump-start/solr9/config-set /solr-conf/conf
ENV SOLR_INSTALL_DIR=/opt/solr

CMD ["solr-precreate", "drupal", "/solr-conf"]
