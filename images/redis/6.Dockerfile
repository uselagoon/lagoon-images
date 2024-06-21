ARG UPSTREAM_REPO
ARG UPSTREAM_TAG
FROM ${UPSTREAM_REPO:-lagoon}/commons:${UPSTREAM_TAG:-latest} as commons
FROM redis:6.2.14-alpine3.19

ENV LAGOON=redis
ENV FLAVOR=ephemeral

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

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
