ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons as commons

FROM mcr.microsoft.com/dotnet/sdk:8.0.303-alpine3.20

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=dotnet-8-sdk

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /sbin/tini /sbin/
COPY --from=commons /home /home

RUN apk add --no-cache bash

RUN fix-permissions /etc/passwd \
    && mkdir -p /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

# Make sure shells are not running forever
COPY 80-shell-timeout.sh /lagoon/entrypoints/
RUN echo "source /lagoon/entrypoints/80-shell-timeout.sh" >> /home/.bashrc

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
