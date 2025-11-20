ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/varnish-8-drupal

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/varnish-persistent-drupal/8.Dockerfile"
LABEL org.opencontainers.image.description="Varnish 8 image optimised for persistent Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/varnish-8-persistent-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/varnish-8-drupal"

VOLUME /var/cache/varnish

ENV CACHE_TYPE=file,/var/cache/varnish/file \
    CACHE_SIZE=950M
