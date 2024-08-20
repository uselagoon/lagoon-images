ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/varnish-6

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/varnish-persistent/6.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Varnish 6 image optimised for persistent workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/varnish-6-persistent"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/varnish-6"

VOLUME /var/cache/varnish

ENV CACHE_TYPE=file,/var/cache/varnish/file \
    CACHE_SIZE=950M
