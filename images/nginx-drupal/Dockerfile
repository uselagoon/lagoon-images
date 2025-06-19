ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/nginx

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/nginx-drupal/Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="OpenResty (Nginx) image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/nginx-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/nginx"

RUN mkdir -p /etc/nginx/conf.d/drupal \
    && mkdir -p /var/run/openresty/nginx-client-body

COPY drupal /etc/nginx/conf.d/drupal/
COPY drupal.conf /etc/nginx/conf.d/app.conf

RUN fix-permissions /etc/nginx
