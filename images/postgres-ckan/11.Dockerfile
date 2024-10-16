ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/postgres-11

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/postgres-ckan/11.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="PostgreSQL 11 image optimised for CKAN workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/postgres-11-ckan"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/postgres-11"

LABEL sh.lagoon.image.deprecated.status="discontinued"

# change log_min_error_statement and log_min_messages from `error` to `log` as drupal is prone to cause some errors which are all logged (yes `log` is a less verbose mode than `error`) 
RUN sed -i "s/#log_min_error_statement = error/log_min_error_statement = log/" /usr/local/share/postgresql/postgresql.conf.sample \
    && sed -i "s/#log_min_messages = warning/log_min_messages = log/" /usr/local/share/postgresql/postgresql.conf.sample

ENV POSTGRES_PASSWORD=ckan \
    POSTGRES_USER=ckan \
    POSTGRES_DB=ckan

COPY 90-datastore-user.sh /docker-entrypoint-initdb.d/
