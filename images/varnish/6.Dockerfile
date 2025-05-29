ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons

FROM varnish:6.0.14 AS vmod

USER root

RUN <<EOF
echo 'Acquire::http::Timeout "60";' >> /etc/apt/apt.conf.d/99timeouts
echo 'Acquire::ftp::Timeout "60";' >> /etc/apt/apt.conf.d/99timeouts
echo 'Acquire::Retries "5";' >> /etc/apt/apt.conf.d/99timeouts
EOF

RUN apt-get update \
    && apt-get -y install \
        build-essential \
        curl \
        zip

RUN curl -s https://packagecloud.io/install/repositories/varnishcache/varnish60lts/script.deb.sh | bash \
    && apt-get -q update \
    && apt search varnish \
    && apt-get -y install \
        automake \
        libpcre3-dev \
        libtool \
        python3-docutils \
        varnish=6.0.14-1~bookworm \
        varnish-dev=6.0.14-1~bookworm

ENV LIBVMOD_DYNAMIC_VERSION=6.0
RUN cd /tmp && curl -sSLO https://github.com/nigoroll/libvmod-dynamic/archive/${LIBVMOD_DYNAMIC_VERSION}.zip \
    && unzip ${LIBVMOD_DYNAMIC_VERSION}.zip && cd libvmod-dynamic-${LIBVMOD_DYNAMIC_VERSION} \
    && ./autogen.sh && ./configure && make && make install

ENV VARNISH_MODULES_VERSION=6.0-lts
RUN cd /tmp && curl -sSLO https://github.com/varnish/varnish-modules/archive/${VARNISH_MODULES_VERSION}.zip \
    && unzip ${VARNISH_MODULES_VERSION}.zip && cd varnish-modules-${VARNISH_MODULES_VERSION} \
    && ./bootstrap && ./configure && make && make install

FROM varnish:6.0.14

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/varnish/6.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Varnish 6 image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/varnish-6"
LABEL org.opencontainers.image.base.name="docker.io/varnish:6.0"

ENV LAGOON=varnish

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /home /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

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
    && rm -rf /var/lib/apt/lists/*

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -sL https://github.com/krallin/tini/releases/download/v0.19.0/tini-${architecture} -o /sbin/tini && chmod a+x /sbin/tini

# Add varnish mod after the varnish package creates the directory.
COPY --from=vmod /usr/lib/varnish/vmods/libvmod_dynamic.* /usr/lib/varnish/vmods/
COPY --from=vmod /usr/lib/varnish/vmods/libvmod_bodyaccess.* /usr/lib/varnish/vmods/

RUN echo "${VARNISH_SECRET:-lagoon_default_secret}" >> /etc/varnish/secret

COPY default.vcl /etc/varnish/default.vcl
COPY varnish-start.bash /varnish-start.sh

RUN fix-permissions /etc/varnish/ \
    && fix-permissions /var/run/ \
    && fix-permissions /var/lib/varnish \
    && usermod -a -G root varnish

COPY docker-entrypoint /lagoon/entrypoints/70-varnish-entrypoint

USER varnish

EXPOSE 8080

# tells the local development environment on which port we are running
ENV LAGOON_LOCALDEV_HTTP_PORT=8080

ENV HTTP_RESP_HDR_LEN=8k \
    HTTP_RESP_SIZE=32k \
    NUKE_LIMIT=150 \
    CACHE_TYPE=malloc \
    CACHE_SIZE=500M \
    LISTEN=":8080" \
    MANAGEMENT_LISTEN=":6082"

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.bash"]
CMD ["/varnish-start.sh"]
