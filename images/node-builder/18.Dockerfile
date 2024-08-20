ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/node-18

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/node-builder/18.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Node.js 18 builder image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/node-18-builder"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/node-18"

RUN apk update \
    && apk add --no-cache \
       libstdc++ \
    && apk add --no-cache \
       bash \
       binutils-gold \
       ca-certificates \
       curl \
       file \
       g++ \
       gcc \
       gcompat \
       git \
       gnupg \
       libgcc \
       libpng-dev \
       linux-headers \
       make \
       openssl \
       python3 \
       wget \
    && rm -rf /var/cache/apk/*

CMD ["/bin/docker-sleep"]
