ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/rabbitmq

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/rabbitmq-cluster/Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="RabbitMQ image optimised for clustered workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/rabbitmq-cluster"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/rabbitmq"

RUN rabbitmq-plugins --offline enable rabbitmq_peer_discovery_k8s

ADD enabled_plugins /etc/rabbitmq/enabled_plugins
ADD rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
RUN fix-permissions /etc/rabbitmq/rabbitmq.conf

ENV RABBITMQ_ERLANG_COOKIE=5188fd99edf19acfefcbb29a16f3d373aa01f66bfe89929852dfad2674d36af2
