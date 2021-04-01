FROM golang:alpine3.12 AS builder
RUN GIT_TAG=github.com/smlx/go-crond@custom-workdir-mod-update GIT_COMMIT=1b81c05ef34903427ed06a56c26cc268a0377b83; \
    GO111MODULE=on CGO_ENABLED=0 go get -ldflags "-X main.gitTag=$GIT_TAG -X main.gitCommit=$GIT_COMMIT" \
    github.com/smlx/go-crond@$GIT_COMMIT
RUN GIT_TAG=github.com/kreuzwerker/envplate@1.0.0-RC1 GIT_COMMIT=977cb694fd31dd89e9326fe4c85572a147011c8f; \
    go get -ldflags "-X=main.build=$GIT_COMMIT -X=main.version=$GIT_TAG" \
    github.com/kreuzwerker/envplate@$GIT_COMMIT \
    && cd /go/pkg/mod/github.com/kreuzwerker/envplate* \
    && go mod init github.com/kreuzwerker/envplate \
    && go install -mod=mod ./bin/ep.go

FROM alpine:3.12.7

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

ENV LAGOON=commons

COPY lagoon/ /lagoon/
RUN mkdir -p /lagoon/bin
COPY fix-permissions docker-sleep entrypoint-readiness wait-for /bin/
COPY .bashrc /home/.bashrc

COPY --from=builder /go/bin/go-crond /lagoon/bin/cron
COPY --from=builder /go/bin/ep /bin/ep

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
