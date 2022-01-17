ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons
# Defining Versions - https://www.elastic.co/guide/en/elasticsearch/reference/7.6/docker.html
FROM docker.elastic.co/elasticsearch/elasticsearch:7.10.2

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=elasticsearch

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /home /home

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -sL https://github.com/krallin/tini/releases/download/v0.19.0/tini-${architecture} -o /sbin/tini && chmod a+x /sbin/tini

COPY docker-entrypoint.sh.7 /lagoon/entrypoints/90-elasticsearch.sh

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

RUN yum -y install zip && yum -y clean all  && rm -rf /var/cache

# Mitigation for CVE-2021-45046 and CVE-2021-44228
RUN zip -q -d /usr/share/elasticsearch/lib/log4j-core-2.11.1.jar org/apache/logging/log4j/core/lookup/JndiLookup.class \
    && zip -q -d /usr/share/elasticsearch/bin/elasticsearch-sql-cli-7.8.1.jar org/apache/logging/log4j/core/lookup/JndiLookup.class

RUN echo $'\n\
node.name: "${HOSTNAME}"\n\
node.master: "${NODE_MASTER}"\n\
node.data: "${NODE_DATA}"\n\
node.ingest: "${NODE_INGEST}"\n\
node.ml: "${NODE_ML}"\n\
xpack.ml.enabled: "${XPACK_ML_ENABLED}"\n\
xpack.watcher.enabled: "${XPACK_WATCHER_ENABLED}"\n\
xpack.security.enabled: "${XPACK_SECURITY_ENABLED}"\n\
processors: "${PROCESSORS}"\n\
cluster.routing.allocation.disk.threshold_enabled: "true"\n\
cluster.remote.connect: "${CLUSTER_REMOTE_CONNECT}"' >> config/elasticsearch.yml

RUN fix-permissions config

ENV ES_JAVA_OPTS="-Xms400m -Xmx400m -Dlog4j2.formatMsgNoLookups=true" \
    NODE_MASTER=true \
    NODE_DATA=true \
    NODE_INGEST=true \
    NODE_ML=true \
    XPACK_ML_ENABLED=true \
    XPACK_WATCHER_ENABLED=true \
    XPACK_SECURITY_ENABLED=false \
    PROCESSORS=2 \
    CLUSTER_REMOTE_CONNECT=true \
    EXTRA_OPTS=""

# Copy es-curl wrapper
COPY es-curl /usr/share/elasticsearch/bin/es-curl


VOLUME [ "/usr/share/elasticsearch/data" ]

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.bash"]

CMD ["/usr/local/bin/docker-entrypoint.sh"]
