ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/node-18:${IMAGE_TAG:-latest}

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
       python3 \
       wget \
    && rm -rf /var/cache/apk/*

CMD ["/bin/docker-sleep"]
