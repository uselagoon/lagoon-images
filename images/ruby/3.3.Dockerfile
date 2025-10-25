ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons
FROM ruby:3.3.10-alpine3.22

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/ruby/3.3.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Ruby 3.3 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/ruby-3.3"
LABEL org.opencontainers.image.base.name="docker.io/ruby:3.3-alpine3.22"

ENV LAGOON=ruby

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /home /home

RUN fix-permissions /etc/passwd \
    && mkdir -p /home

RUN apk update \
    && apk add --no-cache tini \
    && rm -rf /var/cache/apk/*

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
    && gem install webrick puma bundler \
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
CMD ["ruby"]
