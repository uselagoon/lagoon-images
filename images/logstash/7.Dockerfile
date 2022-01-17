ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons
FROM docker.elastic.co/logstash/logstash:7.10.2

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=logstash

USER root

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /home /home

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -sL https://github.com/krallin/tini/releases/download/v0.19.0/tini-${architecture} -o /sbin/tini && chmod a+x /sbin/tini

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

RUN fix-permissions /usr/share/logstash/data \
    && fix-permissions /usr/share/logstash/config

RUN yum -y install zip && yum -y clean all  && rm -rf /var/cache

# Mitigation for CVE-2021-45046 and CVE-2021-44228
RUN zip -q -d /usr/share/logstash/logstash-core/lib/jars/log4j-core-2.12.1.jar org/apache/logging/log4j/core/lookup/JndiLookup.class \
    && zip -q -d /usr/share/logstash/vendor/bundle/jruby/2.5.0/gems/logstash-input-tcp-6.0.6-java/vendor/jar-dependencies/org/logstash/inputs/logstash-input-tcp/6.0.6/logstash-input-tcp-6.0.6.jar org/apache/logging/log4j/core/lookup/JndiLookup.class

ENV LS_JAVA_OPTS "-Xms400m -Xmx400m -Dlog4j2.formatMsgNoLookups=true"

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.bash", "/usr/local/bin/docker-entrypoint"]
