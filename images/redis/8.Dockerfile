ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons
FROM redis:8.0-rc1-alpine3.21

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/redis/8.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Redis 8 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/redis-8"
LABEL org.opencontainers.image.base.name="docker.io/redis:8-alpine3.21"

ENV LAGOON=redis

ENV FLAVOR=ephemeral

# Temp workaround for https://github.com/redis/docker-library-redis/issues/444
COPY apk-tools-static-2.14.6-r3/* /tmp/
RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && mkdir -p /usr/bin \
    && mv /tmp/apk.${architecture}.static /usr/bin/apk.static \
    && rm /tmp/apk.*.static \
    && apk.static -X http://dl-cdn.alpinelinux.org/alpine/v3.21/main -U --allow-untrusted --initdb add apk-tools-static \
    && apk.static update \
    && apk.static -X http://dl-cdn.alpinelinux.org/alpine/v3.21/main -U --allow-untrusted add apk-tools
RUN apk update \
    && apk --repository http://dl-cdn.alpinelinux.org/alpine/v3.21/main/ --allow-untrusted --no-cache add rsync tar

# RUN apk add --no-cache \
#         rsync \
#         tar

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
