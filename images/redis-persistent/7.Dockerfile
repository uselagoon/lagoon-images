ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/redis-7:${IMAGE_TAG:-latest}

ENV FLAVOR=persistent
