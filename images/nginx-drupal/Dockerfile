ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/nginx

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/nginx-drupal/Dockerfile"
LABEL org.opencontainers.image.description="OpenResty (Nginx) image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/nginx-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/nginx"

RUN mkdir -p /etc/nginx/conf.d/drupal

COPY drupal /etc/nginx/conf.d/drupal/
COPY drupal.conf /etc/nginx/conf.d/app.conf

RUN fix-permissions /etc/nginx

