ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/varnish-7-drupal:${IMAGE_TAG:-latest}

VOLUME /var/cache/varnish

ENV CACHE_TYPE=file,/var/cache/varnish/file \
    CACHE_SIZE=950M
