FROM webdevops/go-crond:23.12.0-alpine AS go-crond
FROM amazeeio/envplate:v1.0.3 AS envplate

FROM alpine:3.21.4

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/commons/Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Base image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/commons"
LABEL org.opencontainers.image.base.name="docker.io/alpine:3.21"

ENV LAGOON=commons

COPY lagoon/ /lagoon/
RUN mkdir -p /lagoon/bin \
    && echo $LAGOON_VERSION > /lagoon/version
COPY fix-permissions fix-dir-permissions docker-sleep entrypoint-readiness wait-for /bin/
COPY .bashrc /home/.bashrc

COPY --from=go-crond /usr/local/bin/go-crond /lagoon/bin/cron
COPY --from=envplate /usr/local/bin/ep /bin/ep

RUN apk update \
    && apk add --no-cache \
        apk-tools-static \
        curl \
        rsync \
        tar \
        tini \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /lagoon/crontabs && fix-permissions /lagoon/crontabs \
    && ln -s /home/.bashrc /home/.profile

RUN fix-permissions /etc/passwd

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/bin/docker-sleep"]
