ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/node-16

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=node

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
           git \
           gnupg \
           libgcc \
           libpng-dev \
           linux-headers \
           make \
           openssl \
           python3 \
           wget \
        && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
        && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.34-r0/glibc-2.34-r0.apk \
        && apk add \
               glibc-2.34-r0.apk \
        && rm -rf /var/cache/apk/*

CMD ["/bin/docker-sleep"]
