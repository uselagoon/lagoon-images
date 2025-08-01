ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons
FROM valkey/valkey:8.1.1-alpine3.21


ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/valkey/8.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Valkey 8 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/valkey-8"
LABEL org.opencontainers.image.base.name="docker.io/valkey/valkey:8-alpine"

ENV LAGOON=valkey

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
    && mkdir -p /home \
    && mkdir -p /etc/valkey

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

COPY conf /etc/valkey/
COPY docker-entrypoint /lagoon/entrypoints/70-valkey-entrypoint

RUN fix-permissions /etc/valkey \
    fix-permissions /data

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["valkey-server", "/etc/valkey/valkey.conf"]
