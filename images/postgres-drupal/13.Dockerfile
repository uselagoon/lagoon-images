ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/postgres-13

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/postgres-drupal/13.Dockerfile"
LABEL org.opencontainers.image.description="PostgreSQL 13 image optimised for Drupal workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/postgres-13-drupal"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/postgres-13"

# change log_min_error_statement and log_min_messages from `error` to `log` as drupal is prone to cause some errors which are all logged (yes `log` is a less verbose mode than `error`) 
RUN sed -i "s/#log_min_error_statement = error/log_min_error_statement = log/" /usr/local/share/postgresql/postgresql.conf.sample \
    && sed -i "s/#log_min_messages = warning/log_min_messages = log/" /usr/local/share/postgresql/postgresql.conf.sample

ENV POSTGRES_PASSWORD=drupal \
    POSTGRES_USER=drupal \
    POSTGRES_DB=drupal
