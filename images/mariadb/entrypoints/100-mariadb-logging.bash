#!/usr/bin/env bash

set -eo pipefail

if [ -n "$MARIADB_LOG_SLOW" ]; then
  echo "MARIADB_LOG_SLOW set, logging to /var/log/mariadb-slow.log"
  cat <<EOF > /etc/mysql/conf.d/log-slow.cnf
[mysqld]
log-output=file
slow_query_log = 1
slow_query_log_file = /var/log/mariadb-slow.log
long_query_time = ${MARIADB_LONG_QUERY_TIME:-10}
log_slow_rate_limit = ${MARIADB_LOG_SLOW_RATE_LIMIT:-1}
EOF
fi


if [ -n "$MARIADB_LOG_QUERIES" ]; then
  echo "MARIADB_LOG_QUERIES set, logging to /var/log/mariadb-queries.log"
  cat <<EOF > /etc/mysql/conf.d/log-queries.cnf

[mysqld]
general-log
log-output=file
general-log-file=/var/log/mariadb-queries.log
EOF
fi
