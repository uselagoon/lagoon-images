ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons
# alpine 3.14 as per https://github.com/docker-library/rabbitmq/blob/master/3.8/alpine/Dockerfile
FROM rabbitmq:3.9.3-management-alpine

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

ENV RABBITMQ_DEFAULT_USER='guest' \
    RABBITMQ_DEFAULT_PASS='guest'\
    RABBITMQ_DEFAULT_HA_PATTERN='^$'\
    RABBITMQ_DEFAULT_VHOST='/'

COPY --from=commons /bin/ep /bin/fix-permissions /bin/

RUN wget -O /plugins/rabbitmq_delayed_message_exchange-3.9.0.ez "https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/3.9.0/rabbitmq_delayed_message_exchange-3.9.0.ez" \
    && rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange rabbitmq_prometheus;

# Copy startup schema with vhost, users, permissions and policies
COPY definitions.json /etc/rabbitmq/definitions.json
RUN fix-permissions /etc/rabbitmq/definitions.json

# Copy a custom entrypoint
COPY cluster-rabbit.sh /
RUN fix-permissions /cluster-rabbit.sh && chmod +x /cluster-rabbit.sh

ENTRYPOINT /cluster-rabbit.sh
