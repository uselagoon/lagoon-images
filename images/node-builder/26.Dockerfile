ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/node-26

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/node-builder/26.Dockerfile"
LABEL org.opencontainers.image.description="Node.js 26 builder image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/node-26-builder"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/node-26"

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
