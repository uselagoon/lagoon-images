ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/node-20

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/node-builder/20.Dockerfile"
LABEL org.opencontainers.image.description="Node.js 20 builder image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/node-20-builder"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/node-20"

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
