#!/usr/bin/env bash

set -eo pipefail

if [ "$LAGOON_ENVIRONMENT_TYPE" == "production" ]; then
  # only set if not already defined
  if [ -z ${MARIADB_INNODB_BUFFER_POOL_SIZE+x} ]; then
    export MARIADB_INNODB_BUFFER_POOL_SIZE=1024M
  fi
  if [ -z ${MARIADB_INNODB_LOG_FILE_SIZE+x} ]; then
    export MARIADB_INNODB_LOG_FILE_SIZE=256M
  fi
fi

if [ -n "$MARIADB_PERFORMANCE_SCHEMA" ]; then
  echo "Enabling performance schema"
  cat <<EOF > /etc/mysql/conf.d/performance-schema.cnf
[mysqld]
performance_schema=ON
performance-schema-instrument='stage/%=ON'
performance-schema-consumer-events-stages-current=ON
performance-schema-consumer-events-stages-history=ON
performance-schema-consumer-events-stages-history-long=ON
EOF

fi
