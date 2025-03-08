ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons
FROM alpine:3.19.7

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/mariadb/10.11.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="MariaDB 10.11 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/mariadb-10.11"
LABEL org.opencontainers.image.base.name="docker.io/alpine:3.19"

ENV LAGOON=mariadb

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

ENV BACKUPS_DIR="/var/lib/mysql/backup"

ENV MARIADB_DATABASE=lagoon \
    MARIADB_USER=lagoon \
    MARIADB_PASSWORD=lagoon \
    MARIADB_ROOT_PASSWORD=Lag00n

RUN apk update \
    && apk add --no-cache --virtual .common-run-deps \
        bash \
        curl \
        gettext \
        mariadb-client=10.11.6-r0 \
        mariadb-common=10.11.6-r0 \
        mariadb-server-utils=10.11.6-r0 \
        mariadb=10.11.6-r0 \
        mariadb-connector-c \
        net-tools \
        perl-doc \
        pwgen \
        rsync \
        tar \
        tini \
        tzdata \
        wget \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* /var/tmp/* /var/cache/distfiles/* \
    && rm -rf /var/lib/mysql/* /etc/mysql/ /etc/my.cnf* \
    && curl -sSL https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl -o mysqltuner.pl

COPY entrypoints/ /lagoon/entrypoints/
COPY mysql-backup.sh /lagoon/
COPY my.cnf /etc/mysql/my.cnf

RUN for i in /var/run/mysqld /var/lib/mysql /etc/mysql/conf.d /docker-entrypoint-initdb.d/ "${BACKUPS_DIR}" /home; \
    do mkdir -p $i; chown mysql $i; /bin/fix-permissions $i; \
    done

COPY root/usr/share/container-scripts/mysql/readiness-probe.sh /usr/share/container-scripts/mysql/readiness-probe.sh
RUN /bin/fix-permissions /usr/share/container-scripts/mysql/ \
    && /bin/fix-permissions /etc/mysql

RUN touch /var/log/mariadb-slow.log && /bin/fix-permissions /var/log/mariadb-slow.log \
    && touch /var/log/mariadb-queries.log && /bin/fix-permissions /var/log/mariadb-queries.log

# We cannot start mysql as root, we add the user mysql to the group root and
# change the user of the Docker Image to this user.
RUN addgroup mysql root
USER mysql
ENV USER_NAME mysql

WORKDIR /var/lib/mysql
VOLUME /var/lib/mysql
EXPOSE 3306

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.bash"]
CMD ["mysqld"]
