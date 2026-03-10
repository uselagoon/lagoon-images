ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS commons
FROM solr:10.0.0

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/solr/10.Dockerfile"
LABEL org.opencontainers.image.description="Solr 10 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/solr-10"
LABEL org.opencontainers.image.base.name="docker.io/solr:10"

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

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
    && rm -rf /var/lib/apt/lists/*

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -sL https://github.com/krallin/tini/releases/download/v0.19.0/tini-${architecture} -o /sbin/tini && chmod a+x /sbin/tini

RUN mkdir -p /var/solr /opt/solr/server/logs /opt/solr/server/solr
RUN fix-permissions /var/solr \
    && chown solr:solr /var/solr /opt/solr/server/logs /opt/solr/server/solr \
    && fix-permissions /opt/solr/server/logs \
    && fix-permissions /opt/solr/server/solr

COPY solr-recreate.sh /opt/solr/docker/scripts/solr-recreate
COPY solr-foreground.sh /opt/solr/docker/scripts/solr-foreground
RUN chmod 775 /opt/solr/docker/scripts/solr-recreate /opt/solr/docker/scripts/solr-foreground

# solr really doesn't like to be run as root, so we define the default user again
USER solr

ENV SOLR_OPTS="-Dlog4j2.formatMsgNoLookups=true"

# Define Volume so locally we get persistent cores
VOLUME /var/solr

# Define provided solr-docker entrypoint to append
ENV APPEND_NATIVE_ENTRYPOINT=/opt/solr/docker/scripts/docker-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.bash"]

# solr-precreate creates the core on disk then calls solr-foreground.
# solr-foreground injects --user-managed unless SOLR_CLOUD_MODE=true,
# keeping standalone mode despite Solr 10 defaulting to SolrCloud.
CMD ["solr-precreate", "mycore"]
