ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/redis-6

ENV FLAVOR=persistent
