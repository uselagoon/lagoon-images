#!/usr/bin/env bash

set -eo pipefail

if [ -n "$MYSQL_LOG_SLOW" ]; then
  echo "MYSQL_LOG_SLOW set, logging to /etc/mysql/conf.d/log-slow.cnf"
  cat <<EOF > /etc/mysql/conf.d/log-slow.cnf
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql-slow.log
EOF
fi


if [ -n "$MYSQL_LOG_QUERIES" ]; then
  echo "MYSQL_LOG_QUERIES set, logging to /etc/mysql/conf.d/log-queries.cnf"
  cat <<EOF > /etc/mysql/conf.d/log-queries.cnf

[mysqld]
general-log
log-output=file
general-log-file=/var/log/mysql-queries.log
EOF
fi
