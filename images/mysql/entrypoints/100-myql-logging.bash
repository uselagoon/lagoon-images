#!/usr/bin/env bash

set -eo pipefail

if [ -n "$MYSQL_LOG_SLOW" ]; then
  echo "MYSQL_LOG_SLOW set, logging to /var/log/mysql-slow.log"
  cat <<EOF > /etc/mysql/conf.d/log-slow.cnf
[mysqld]
log_output=file
slow_query_log = 1
slow_query_log_file = /var/log/mysql-slow.log
long_query_time = ${MYSQL_LONG_QUERY_TIME:-10}
log_slow_rate_limit = ${MYSQL_LOG_SLOW_RATE_LIMIT:-1}
EOF
fi


if [ -n "$MYSQL_LOG_QUERIES" ]; then
  echo "MYSQL_LOG_QUERIES set, logging to /var/log/mysql-queries.log"
  cat <<EOF > /etc/mysql/conf.d/log-queries.cnf

[mysqld]
general-log
log-output=file
general-log-file=/var/log/mysql-queries.log
EOF
fi
