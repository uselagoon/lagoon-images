ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/nginx

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=nginx

RUN mkdir -p /etc/nginx/conf.d/drupal

COPY drupal /etc/nginx/conf.d/drupal/
COPY drupal.conf /etc/nginx/conf.d/app.conf

RUN fix-permissions /etc/nginx
