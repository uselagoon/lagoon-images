ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS jumpstart

ADD https://git.drupalcode.org/project/search_api_solr.git#4.3.3 /search_api_solr

ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/solr-9

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/solr-drupal/9.Dockerfile"
LABEL org.opencontainers.image.description="Solr 9 image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/solr-9-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/solr-9"

COPY --from=jumpstart /search_api_solr/jump-start/solr9/config-set /solr-conf/conf
ENV SOLR_INSTALL_DIR=/opt/solr

ENV SOLR_MODULES="extraction,langid,ltr,analysis-extras"

CMD ["solr-precreate", "drupal", "/solr-conf"]
