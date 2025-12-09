ARG LOCAL_REPO
FROM ${LOCAL_REPO:-lagoon}/commons AS commons

FROM python:3.13.11-alpine3.22

LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/python/3.13.Dockerfile"
LABEL org.opencontainers.image.description="Python 3.13 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/python-3.13"
LABEL org.opencontainers.image.base.name="docker.io/python:3.13-alpine3.22"

ENV LAGOON=python

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /sbin/tini /sbin/
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

RUN apk update \
    && apk add --no-cache --virtual .build-deps \
        build-base \
    && pip install --upgrade pip \
    && pip install virtualenv \
    && apk del \
        .build-deps \
    && apk add --no-cache \
        rsync \
        tar \
    && rm -rf /var/cache/apk/*

# Make sure shells are not running forever
COPY 80-shell-timeout.sh /lagoon/entrypoints/
RUN echo "source /lagoon/entrypoints/80-shell-timeout.sh" >> /home/.bashrc

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["python"]
