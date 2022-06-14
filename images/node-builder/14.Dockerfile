ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/node-14

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=node

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
        libstdc++ \
    && apk add --no-cache \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        git \
        file \
        openssl \
        bash \
        ca-certificates \
        wget \
        libpng-dev \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk \
    && apk add glibc-2.28-r0.apk \
    && rm -rf /var/cache/apk/*

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.15/main' >> /etc/apk/repositories \
    && echo 'http://dl-cdn.alpinelinux.org/alpine/v3.15/community' >> /etc/apk/repositories \
    && apk update \
    && apk add python2=~2.7 \
    && rm -rf /var/cache/apk/*

CMD ["/bin/docker-sleep"]
