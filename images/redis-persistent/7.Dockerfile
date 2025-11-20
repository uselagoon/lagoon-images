ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/redis-7

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/redis-persistent/7.Dockerfile"
LABEL org.opencontainers.image.description="Redis 7 image optimised for persistent workloads running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/redis-7-persistent"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/redis-7"

ENV FLAVOR=persistent
