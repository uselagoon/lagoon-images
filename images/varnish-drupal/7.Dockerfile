ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/varnish-7

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

USER root

COPY drupal.vcl /etc/varnish/default.vcl
RUN fix-permissions /etc/varnish/default.vcl

USER varnish
