ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/varnish-6.5

COPY drupal.vcl /etc/varnish/default.vcl

RUN fix-permissions /etc/varnish/default.vcl
