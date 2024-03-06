ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/nginx:${IMAGE_TAG:-latest}

ENV LAGOON=nginx

RUN mkdir -p /etc/nginx/conf.d/drupal

COPY drupal /etc/nginx/conf.d/drupal/
COPY drupal.conf /etc/nginx/conf.d/app.conf

RUN fix-permissions /etc/nginx
