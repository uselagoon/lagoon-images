FROM alpine:3.19.3

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

RUN wget -O /tmp/mysql-8.0.tar.gz https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-boost-8.0.39.tar.gz

RUN apk add -U --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.16/main boost1.77-dev \
    && apk add --no-cache --virtual .devdeps \
        bash \
        build-base \
        ca-certificates \
        autoconf \
        openssl \
        openssl-dev \
        ncurses \
        ncurses-dev \
        wget \
        cmake \
    && cd /tmp && tar -zxf /tmp/mysql-8.0.tar.gz \
    && cd /tmp/mysql* && cmake -DFORCE_INSOURCE_BUILD=1 -DWITHOUT_SERVER:BOOL=ON -DCMAKE_INSTALL_PREFIX=/ \
    && make && make install  \
    && rm -rf /tmp/mysql* \
    && apk del -r .devdeps \
    && rm -rf /var/cache/apk/*
