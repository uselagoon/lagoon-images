#!/bin/bash
#
# mysqld readinessProbe for use in kubernetes
#

mysql --defaults-file=${MYSQL_DATA_DIR:-/var/lib/mysql}/.my.cnf -e"SHOW DATABASES;"

if [ $? -ne 0 ]; then
  exit 1
else
  exit 0
fi
