ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as jumpstart

ADD https://git.drupalcode.org/project/search_api_solr.git#4.3.3 /search_api_solr

ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-8

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

COPY --from=jumpstart /search_api_solr/jump-start/solr8/config-set /solr-conf/conf
ENV SOLR_INSTALL_DIR=/opt/solr

CMD ["solr-precreate", "drupal", "/solr-conf"]