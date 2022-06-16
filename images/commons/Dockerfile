FROM webdevops/go-crond:21.5.0-alpine AS go-crond
FROM amazeeio/envplate:v1.0.0-rc.3 AS envplate

FROM alpine:3.16.0

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=commons

COPY lagoon/ /lagoon/
RUN mkdir -p /lagoon/bin
COPY fix-permissions docker-sleep entrypoint-readiness wait-for /bin/
COPY .bashrc /home/.bashrc

COPY --from=go-crond /usr/local/bin/go-crond /lagoon/bin/cron
COPY --from=envplate /usr/local/bin/ep /bin/ep

RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl tini \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /lagoon/crontabs && fix-permissions /lagoon/crontabs \
    && ln -s /home/.bashrc /home/.profile

RUN fix-permissions /etc/passwd

ARG LAGOON_VERSION
RUN echo $LAGOON_VERSION > /lagoon/version
ENV LAGOON_VERSION=$LAGOON_VERSION

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/bin/docker-sleep"]
