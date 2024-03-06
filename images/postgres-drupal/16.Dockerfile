ARG IMAGE_REPO
ARG IMAGE_TAG
FROM ${IMAGE_REPO:-lagoon}/postgres-16:${IMAGE_TAG:-latest}

# change log_min_error_statement and log_min_messages from `error` to `log` as drupal is prone to cause some errors which are all logged (yes `log` is a less verbose mode than `error`) 
RUN sed -i "s/#log_min_error_statement = error/log_min_error_statement = log/" /usr/local/share/postgresql/postgresql.conf.sample \
    && sed -i "s/#log_min_messages = warning/log_min_messages = log/" /usr/local/share/postgresql/postgresql.conf.sample

ENV POSTGRES_PASSWORD=drupal \
    POSTGRES_USER=drupal \
    POSTGRES_DB=drupal
