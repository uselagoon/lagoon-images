ARG UPSTREAM_REPO
ARG UPSTREAM_TAG
FROM ${UPSTREAM_REPO:-lagoon}/redis-6:${UPSTREAM_TAG:-latest}

ENV FLAVOR=persistent
