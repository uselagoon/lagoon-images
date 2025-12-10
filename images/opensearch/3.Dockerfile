ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS commons
FROM opensearchproject/opensearch:3.3.2

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/opensearch/3.Dockerfile"
LABEL org.opencontainers.image.description="OpenSearch 3 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/opensearch-3"
LABEL org.opencontainers.image.base.name="docker.io/opensearchproject/opensearch:3"

ENV LAGOON=opensearch

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/fix-dir-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /home /home

USER root

RUN dnf update --releasever=latest -y \
    && dnf install -y \
        findutils \
        rsync \
        tar \
        util-linux-core \
    && dnf clean all

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -sL https://github.com/krallin/tini/releases/download/v0.19.0/tini-${architecture} -o /usr/sbin/tini && chmod a+x /usr/sbin/tini

RUN fix-permissions /etc/passwd \
    && mkdir -p /home

# Reproduce behavior of Alpine: Run Bash as sh
RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

# Uninstall the unneeded plugins
RUN for plugin in \
  opensearch-security-analytics \
  opensearch-alerting \
  opensearch-anomaly-detection \
  opensearch-cross-cluster-replication \
  opensearch-index-management \
  opensearch-ml \
  opensearch-notifications \
  opensearch-notifications-core \
  opensearch-observability \
  opensearch-reports-scheduler \
  opensearch-security \
  opensearch-skills; do \
  /usr/share/opensearch/bin/opensearch-plugin remove --purge $plugin; \
  done

ENV OPENSEARCH_JAVA_OPTS="-Xms512m -Xmx512m" \
    EXTRA_OPTS=""

# Copy es-curl wrapper
COPY es-curl /usr/share/opensearch/bin/es-curl

COPY docker-entrypoint.sh /lagoon/entrypoints/80-opensearch.sh

RUN fix-permissions /usr/share/opensearch/config \
    && fix-dir-permissions /usr/share/opensearch

USER opensearch

VOLUME [ "/usr/share/opensearch/data" ]

ENTRYPOINT ["/usr/sbin/tini", "--", "/lagoon/entrypoints.bash"]

CMD ["/usr/share/opensearch/opensearch-docker-entrypoint.sh"]
