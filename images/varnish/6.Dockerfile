ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons

FROM varnish:6.6 as vmod
ENV LIBVMOD_DYNAMIC_VERSION=6.5
ENV VARNISH_MODULES_VERSION=6.5
RUN apt-get update && apt-get -y install build-essential automake libtool python-docutils libpcre3-dev varnish-dev curl zip

RUN cd /tmp && curl -sSLO https://github.com/nigoroll/libvmod-dynamic/archive/${LIBVMOD_DYNAMIC_VERSION}.zip && \
  unzip ${LIBVMOD_DYNAMIC_VERSION}.zip && cd libvmod-dynamic-${LIBVMOD_DYNAMIC_VERSION} && \
  ./autogen.sh && ./configure && make && make install

RUN cd /tmp && curl -sSLO https://github.com/varnish/varnish-modules/archive/${VARNISH_MODULES_VERSION}.zip && \
  unzip ${VARNISH_MODULES_VERSION}.zip && cd varnish-modules-${VARNISH_MODULES_VERSION} && \
  ./bootstrap && ./configure && make && make install

FROM varnish:6.6

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=varnish

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/
#COPY --from=commons /sbin/tini /sbin/
COPY --from=commons /home /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

# Add varnish mod after the varnish package creates the directory.
COPY --from=vmod /usr/lib/varnish/vmods/libvmod_dynamic.* /usr/lib/varnish/vmods/
COPY --from=vmod /usr/lib/varnish/vmods/libvmod_bodyaccess.* /usr/lib/varnish/vmods/

RUN echo "${VARNISH_SECRET:-lagoon_default_secret}" >> /etc/varnish/secret

COPY default.vcl /etc/varnish/default.vcl
COPY varnish-start.sh /varnish-start.sh

# needed to fix dash upgrade - man files are removed from slim images
RUN set -x \
    && mkdir -p /usr/share/man/man1 \
    && touch /usr/share/man/man1/sh.distrib.1.gz

# replace default dash shell with bash to allow for bashisms
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

RUN chmod +x /sbin/tini

RUN fix-permissions /etc/varnish/ \
    && fix-permissions /var/run/ \
    && fix-permissions /var/lib/varnish

COPY docker-entrypoint /lagoon/entrypoints/70-varnish-entrypoint

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

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/varnish-start.sh"]
