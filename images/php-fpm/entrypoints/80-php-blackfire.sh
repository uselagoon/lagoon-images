#!/bin/bash

# enable blackfire only if BLACKFIRE_ENABLED is set
if [ ${BLACKFIRE_ENABLED+x} ]; then

  # if BLACKFIRE_AGENT_SOCKET is not set already, check if we can access well known locations
  if [ -z "${BLACKFIRE_AGENT_SOCKET}" ]; then
    # check for blackfire running in cluster
    if nc -z -w 1 blackfire.blackfire.svc.cluster.local 8707 &> /dev/null; then
      export BLACKFIRE_AGENT_SOCKET=tcp://blackfire.blackfire.svc.cluster.local:8707
    # check for blackfire running in same namespace
    elif nc -z -w 1 blackfire 8707 &> /dev/null; then
      export BLACKFIRE_AGENT_SOCKET=tcp://blackfire:8707
    fi
  fi

  # envplate the blackfire ini file
  ep /usr/local/etc/php/conf.d/blackfire.disable

  # copy the envplated file so that php will use it
  cp /usr/local/etc/php/conf.d/blackfire.disable /usr/local/etc/php/conf.d/blackfire.ini

fi