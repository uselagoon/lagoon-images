ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS commons
FROM postgres:14.20-alpine3.23

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/postgres/14.Dockerfile"
LABEL org.opencontainers.image.description="PostgreSQL 14 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/postgres-14"
LABEL org.opencontainers.image.base.name="docker.io/postgres:14-alpine3.23"

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
