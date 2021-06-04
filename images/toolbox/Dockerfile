ARG IMAGE_REPO

FROM ${IMAGE_REPO:-lagoon}/mariadb-10.5 as mariadb

FROM ${IMAGE_REPO:-lagoon}/commons as commons

LABEL org.opencontainers.image.authors="The Lagoon Authors" maintainer="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images" repository="https://github.com/uselagoon/lagoon-images"

RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl ncdu socat ca-certificates openssl perl perl-doc mysql-client rsync mariadb-mytop redis postgresql-client \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/* \
    && wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl -O mysqltuner.pl \
    && chmod +x mysqltuner.pl

COPY --from=mariadb /usr/bin/my_print_defaults /usr/bin/my_print_defaults
