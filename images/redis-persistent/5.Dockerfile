ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/redis-5

ENV FLAVOR=persistent
