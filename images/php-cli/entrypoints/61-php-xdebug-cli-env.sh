#!/bin/sh

# enable XDebug only if XDEBUG_ENABLE is set to true or TRUE or True
if expr "$XDEBUG_ENABLE" : '[Tt][Rr][Uu][Ee]' > /dev/null; then
  # XDEBUG_CONFIG is used by xdebug to decide if an xdebug session should be started in the CLI or not.
  # The content doesn't really matter it just needs to be set, the actual connection details are loaded from /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
  export XDEBUG_SESSION="idekey=lagoon"

  # PHP_IDE_CONFIG is used by PhpStorm and should be the URL of the project, we use the `LAGOON_ROUTE` for it (if it exists)
  if [ ${LAGOON_ROUTE+x} ]; then
    SERVERNAME=$(echo $LAGOON_ROUTE | sed 's/https\?:\/\///')
  else
    SERVERNAME="lagoon"
  fi
  export PHP_IDE_CONFIG="serverName=${SERVERNAME}"
fi

