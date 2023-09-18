ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/node-16

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=node

RUN apk add --no-cache git \
        unzip \
        gzip  \
        bash \
        openssh-client \
        rsync \
        patch \
        procps \
        coreutils \
        mariadb-client \
        mariadb-connector-c \
        postgresql-client \
        mongodb-tools \
        openssh-sftp-server \
        findutils \
    && ln -s /usr/lib/ssh/sftp-server /usr/local/bin/sftp-server \
    && rm -rf /var/cache/apk/* \
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
COPY id_ed25519_lagoon_cli.key /home/.ssh/lagoon_cli.key
RUN chmod 400 /home/.ssh/lagoon_cli.key
ENV SSH_AUTH_SOCK=/tmp/ssh-agent

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/bin/docker-sleep"]
