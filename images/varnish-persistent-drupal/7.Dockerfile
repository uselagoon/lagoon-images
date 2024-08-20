ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/varnish-7-drupal

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/varnish-persistent-drupal/7.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Varnish 7 image optimised for persistent Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/varnish-7-persistent-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/varnish-7-drupal"

VOLUME /var/cache/varnish

ENV CACHE_TYPE=file,/var/cache/varnish/file \
    CACHE_SIZE=950M
