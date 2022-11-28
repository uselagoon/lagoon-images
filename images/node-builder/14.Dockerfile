ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/node-14

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
           gcompat \
           git \
           gnupg \
           libgcc \
           libpng-dev \
           linux-headers \
           make \
           openssl \
           wget \
    && rm -rf /var/cache/apk/*

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.15/main' >> /etc/apk/repositories \
    && echo 'http://dl-cdn.alpinelinux.org/alpine/v3.15/community' >> /etc/apk/repositories \
    && apk update \
    && apk add \
           python2=~2.7 \
    && rm -rf /var/cache/apk/*

CMD ["/bin/docker-sleep"]
