ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/varnish-7

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/varnish-drupal/7.Dockerfile"
LABEL org.opencontainers.image.description="Varnish 7 image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/varnish-7-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/varnish-7"

USER root

COPY drupal.vcl /etc/varnish/default.vcl
RUN fix-permissions /etc/varnish/default.vcl

USER varnish
