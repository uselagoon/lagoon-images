ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/varnish-7:${IMAGE_TAG:-latest}

USER root

COPY drupal.vcl /etc/varnish/default.vcl
RUN fix-permissions /etc/varnish/default.vcl

USER varnish
