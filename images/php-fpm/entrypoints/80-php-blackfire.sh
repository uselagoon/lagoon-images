#!/bin/bash

# enable blackfire only if BLACKFIRE_ENABLED is set to true or TRUE or True
if expr "$BLACKFIRE_ENABLED" : '[Tt][Rr][Uu][Ee]' > /dev/null; then

  # start the blackfire-agent
  /bin/blackfire agent --log-level="${BLACKFIRE_LOG_LEVEL:-3}" --socket="${BLACKFIRE_SOCKET:-"tcp://127.0.0.1:8307"}" &

  # envplate the blackfire ini file
  ep /usr/local/etc/php/conf.d/blackfire.disable

  # copy the envplated file so that php will use it
  cp /usr/local/etc/php/conf.d/blackfire.disable /usr/local/etc/php/conf.d/blackfire.ini

fi