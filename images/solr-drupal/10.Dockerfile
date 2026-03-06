ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS jumpstart

ADD https://git.drupalcode.org/project/search_api_solr.git#4.3.10 /search_api_solr

ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/solr-10

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/solr-drupal/10.Dockerfile"
LABEL org.opencontainers.image.description="Solr 10 image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/solr-10-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/solr-10"

# search_api_solr does not yet ship a solr10 jump-start config-set; the solr9
# config-set is forward-compatible with Solr 10 and is the recommended starting
# point until an explicit solr10 config-set is released.
COPY --from=jumpstart /search_api_solr/jump-start/solr9/config-set /solr-conf/conf
ENV SOLR_INSTALL_DIR=/opt/solr

ENV SOLR_MODULES="extraction,langid,ltr,analysis-extras"

CMD ["solr-precreate", "drupal", "/solr-conf"]
