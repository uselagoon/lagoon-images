ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons
FROM solr:8.11.2-slim

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=solr
ENV SOLR_DATA_HOME=/var/solr
ENV SOLR_LOGS_DIR=/opt/solr/server/logs

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/
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

RUN apt-get -y update && apt-get -y install \
    busybox \
    curl \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Mitigation for CVE-2021-45046 and CVE-2021-44228 - not needed in log4j-core 2.16.0
#  RUN zip -q -d /opt/solr-8.10.1/server/lib/ext/log4j-core-2.14.1.jar org/apache/logging/log4j/core/lookup/JndiLookup.class \
#      && zip -q -d /opt/solr-8.10.1/contrib/prometheus-exporter/lib/log4j-core-2.14.1.jar org/apache/logging/log4j/core/lookup/JndiLookup.class

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

COPY solr-recreate.sh /opt/docker-solr/scripts/solr-recreate
RUN chmod 775 /opt/docker-solr/scripts/solr-recreate

# solr really doesn't like to be run as root, so we define the default user agin
USER solr

ENV SOLR_OPTS="-Dlog4j2.formatMsgNoLookups=true"

COPY 10-solr-port.sh /lagoon/entrypoints/
# currently, there is no smart upgrade path from 7 to 8 - no autoremediation etc
# and whilst sites may work, upgrading from 7 to 8, they won't work downgrading...
# COPY 20-solr-datadir.sh /lagoon/entrypoints/

# Define Volume so locally we get persistent cores
VOLUME /var/solr

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]

CMD ["solr-precreate", "mycore"]
