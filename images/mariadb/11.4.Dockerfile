ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS commons
FROM mariadb:11.4.10-ubi9

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/mariadb/11.4.Dockerfile"
LABEL org.opencontainers.image.description="MariaDB 11.4 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/mariadb-11.4"
LABEL org.opencontainers.image.base.name="docker.io/mariadb:11.4-ubi9"

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

ENV LAGOON=mariadb

USER root

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
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

RUN printf "[main]\nexcludepkgs=MariaDB*" > /etc/dnf/dnf.conf \
    && microdnf install -y epel-release \
    && microdnf install -y \
        gettext \
        openssh-clients \
        pwgen \
        rsync \
        tar \
        wget \
    && microdnf clean all \
    && rm -rf /var/lib/mysql/* /etc/mysql/ /etc/my.cnf* \
    && curl -sSL https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl -o mysqltuner.pl

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -sL https://github.com/krallin/tini/releases/download/v0.19.0/tini-${architecture} -o /sbin/tini && chmod a+x /sbin/tini

COPY entrypoints/ /lagoon/entrypoints/
COPY mysql-backup.sh /lagoon/
COPY my.11.cnf /etc/mysql/my.cnf

RUN rm /lagoon/entrypoints/9999-mariadb-init.10.bash \
    && mv /lagoon/entrypoints/9999-mariadb-init.11.bash /lagoon/entrypoints/9999-mariadb-init.bash \
    && echo "!include /etc/mysql/my.cnf" >> /etc/my.cnf

RUN for i in /var/run/mysqld /run/mariadb /run/mysqld /var/lib/mysql /etc/mysql/conf.d /docker-entrypoint-initdb.d /home; \
    do mkdir -p $i; chown mysql $i; /bin/fix-permissions $i; \
    done

COPY root/usr/share/container-scripts/mysql/readiness-probe.sh /usr/share/container-scripts/mysql/readiness-probe.sh
RUN /bin/fix-permissions /usr/share/container-scripts/mysql/ \
    && /bin/fix-permissions /etc/mysql

RUN touch /var/log/mariadb-slow.log && /bin/fix-permissions /var/log/mariadb-slow.log \
    && touch /var/log/mariadb-queries.log && /bin/fix-permissions /var/log/mariadb-queries.log

# We cannot start mysql as root, we add the user mysql to the group root and
# ensure that the gid and uid match the previous image releases and then we
# change the user of the Docker Image to this user.
RUN groupmod -o -g 101 mysql \
    && usermod -u 100 mysql \
    && usermod -a -G root mysql

USER mysql
ENV USER_NAME=mysql

WORKDIR /var/lib/mysql
EXPOSE 3306

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.bash"]
CMD ["mariadbd"]
