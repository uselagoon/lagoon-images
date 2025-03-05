ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/node-22

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/node-cli/22.Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="Node.js 22 cli image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/node-22-cli"
LABEL org.opencontainers.image.base.name="docker.io/uselagoon/node-22"

COPY mariadb-client-10.11.6-apk/ /tmp/

RUN architecture=$(case $(uname -m) in x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && apk add --allow-untrusted --no-cache \
        /tmp/$architecture-mariadb-client-10.11.6-r0.apk \
        /tmp/$architecture-mariadb-common-10.11.6-r0.apk \
    && apk add --no-cache bash \
        coreutils \
        findutils \
        git \
        gzip  \
        mariadb-connector-c \
        mongodb-tools \
        openssh-client \
        openssh-sftp-server \
        patch \
        postgresql-client \
        procps \
        unzip \
    && rm -rf /var/cache/apk/* \
    && ln -s /usr/lib/ssh/sftp-server /usr/local/bin/sftp-server \
    && mkdir -p /home/.ssh \
    && fix-permissions /home/

# We not only use "export $PATH" as this could be overwritten again
# like it happens in /etc/profile of alpine Images.
COPY entrypoints /lagoon/entrypoints/

# Make sure shells are not running forever
RUN echo "source /lagoon/entrypoints/80-shell-timeout.sh" >> /home/.bashrc

# Copy mariadb-client configuration.
COPY mariadb-client.cnf /etc/my.cnf.d/
RUN fix-permissions /etc/my.cnf.d/

# SSH Key and Agent Setup
COPY ssh_config /etc/ssh/ssh_config
RUN sed -i '/# Deprecated: lagoon_cli.key/,+2d' /etc/ssh/ssh_config
ENV SSH_AUTH_SOCK=/tmp/ssh-agent

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/bin/docker-sleep"]
