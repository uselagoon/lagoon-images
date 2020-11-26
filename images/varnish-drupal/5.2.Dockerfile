ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/varnish-5.2

COPY drupal.vcl /etc/varnish/default.vcl

RUN fix-permissions /etc/varnish/default.vcl
