ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS commons
FROM redis:8.6.1-alpine3.23

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/redis/8.Dockerfile"
LABEL org.opencontainers.image.description="Redis 8 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/redis-8"
LABEL org.opencontainers.image.base.name="docker.io/redis:8.6.0-alpine3.23"

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

ENV LAGOON=redis

ENV FLAVOR=ephemeral

RUN apk add --no-cache \
        rsync \
        tar

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /sbin/tini /sbin/
COPY --from=commons /home /home

RUN fix-permissions /etc/passwd \
    && mkdir -p /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

COPY conf /etc/redis/
COPY docker-entrypoint /lagoon/entrypoints/70-redis-entrypoint

RUN fix-permissions /etc/redis \
    fix-permissions /data

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["redis-server", "/etc/redis/redis.conf"]
