ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons
FROM postgres:15.13-alpine3.21

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/postgres/12.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="PostgreSQL 12 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/postgres-12"
LABEL org.opencontainers.image.base.name="docker.io/postgres:12-alpine3.21"

LABEL sh.lagoon.image.deprecated.status="endoflife"
LABEL sh.lagoon.image.deprecated.suggested="docker.io/uselagoon/postgres-17"

ENV LAGOON=postgres

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /sbin/tini /sbin/
COPY --from=commons /home /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

RUN apk update \
    && apk add --no-cache \
        rsync \
        tar \
    && rm -rf /var/cache/apk/*

RUN fix-permissions /etc/passwd \
    && mkdir -p /home

COPY postgres-backup.sh /lagoon/

RUN echo -e "local all all md5\nhost  all  all 0.0.0.0/0 md5" >> /usr/local/share/postgresql/pg_hba.conf

ENV PGUSER=postgres \
    POSTGRES_PASSWORD=lagoon \
    POSTGRES_USER=lagoon \
    POSTGRES_DB=lagoon \
    PGDATA=/var/lib/postgresql/data/pgdata

# Postgresql entrypoint file needs bash, so start the entrypoints with bash
ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.bash"]
CMD ["/usr/local/bin/docker-entrypoint.sh", "postgres"]
