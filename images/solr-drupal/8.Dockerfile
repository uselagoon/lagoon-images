ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as jumpstart

ADD https://git.drupalcode.org/project/search_api_solr.git#4.3.3 /search_api_solr

ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/solr-8

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/solr-drupal/8.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Solr 8 image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/solr-8-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/solr-8"

LABEL sh.lagoon.image.deprecated.status="endoflife"
LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/solr-9-drupal"

COPY --from=jumpstart /search_api_solr/jump-start/solr8/config-set /solr-conf/conf
ENV SOLR_INSTALL_DIR=/opt/solr

CMD ["solr-precreate", "drupal", "/solr-conf"]
