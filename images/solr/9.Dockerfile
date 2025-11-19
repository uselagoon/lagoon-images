ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons
FROM solr:9.10.0

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/solr/9.Dockerfile"
LABEL org.opencontainers.image.description="Solr 9 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/solr-9"
LABEL org.opencontainers.image.base.name="docker.io/solr:9"

ENV LAGOON=solr

ENV SOLR_DATA_HOME=/var/solr
ENV SOLR_LOGS_DIR=/opt/solr/server/logs

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /home/.bashrc /home/.bashrc

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

# we need root for the fix-permissions to work
USER root

RUN <<EOF
echo 'Acquire::http::Timeout "60";' >> /etc/apt/apt.conf.d/99timeouts
echo 'Acquire::ftp::Timeout "60";' >> /etc/apt/apt.conf.d/99timeouts
echo 'Acquire::Retries "5";' >> /etc/apt/apt.conf.d/99timeouts
EOF

RUN apt-get -y update \
    && apt-get -y install \
        busybox \
        curl \
        tar \
        zip \
    # Temp fix for rsync RCE vulnerability https://ubuntu.com/blog/rsync-remote-code-execution
    && apt satisfy -y "rsync (>= 3.1.3-8ubuntu0.8)" \
    && rm -rf /var/lib/apt/lists/*

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -sL https://github.com/krallin/tini/releases/download/v0.19.0/tini-${architecture} -o /sbin/tini && chmod a+x /sbin/tini

# needed to fix dash upgrade - man files are removed from slim images
RUN set -x \
    && mkdir -p /usr/share/man/man1 \
    && touch /usr/share/man/man1/sh.distrib.1.gz

# replace default dash shell with bash to allow for bashisms
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

RUN mkdir -p /var/solr /opt/solr/server/logs /opt/solr/server/solr 
RUN fix-permissions /var/solr \
    && chown solr:solr /var/solr /opt/solr/server/logs /opt/solr/server/solr \
    && fix-permissions /opt/solr/server/logs \
    && fix-permissions /opt/solr/server/solr

COPY solr-recreate.sh /opt/solr/docker/scripts/solr-recreate
RUN chmod 775 /opt/solr/docker/scripts/solr-recreate

# solr really doesn't like to be run as root, so we define the default user agin
USER solr

ENV SOLR_OPTS="-Dlog4j2.formatMsgNoLookups=true"

# Define Volume so locally we get persistent cores
VOLUME /var/solr

# Define provided solr-docker entrypoint to append
ENV APPEND_NATIVE_ENTRYPOINT=/opt/solr/docker/scripts/docker-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]

CMD ["solr-precreate", "mycore"]
