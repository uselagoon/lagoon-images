ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons
FROM solr:6.6.6-alpine

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=solr

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /sbin/tini /sbin/
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

RUN mkdir -p /var/solr
RUN fix-permissions /var/solr \
    && chown solr:solr /var/solr \
    && fix-permissions /opt/solr/server/logs \
    && fix-permissions /opt/solr/server/solr


# solr really doesn't like to be run as root, so we define the default user agin
USER solr

COPY 10-solr-port.sh /lagoon/entrypoints/
COPY 20-solr-datadir.sh /lagoon/entrypoints/


# Define Volume so locally we get persistent cores
VOLUME /var/solr

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]

CMD ["solr-precreate", "mycore"]
