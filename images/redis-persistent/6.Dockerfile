ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/redis-6

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/redis-persistent/6.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Redis 6 image optimised for persistent workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/redis-6-persistent"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/redis-6"

ENV FLAVOR=persistent
