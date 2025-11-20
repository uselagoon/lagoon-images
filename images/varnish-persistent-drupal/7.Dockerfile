ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/varnish-7-drupal

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/varnish-persistent-drupal/7.Dockerfile"
LABEL org.opencontainers.image.description="Varnish 7 image optimised for persistent Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/varnish-7-persistent-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/varnish-7-drupal"

VOLUME /var/cache/varnish

ENV CACHE_TYPE=file,/var/cache/varnish/file \
    CACHE_SIZE=950M
