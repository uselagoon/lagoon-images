#!/bin/sh

# This script will be the default ENTRYPOINT for all children docker images.
# It just sources all files within /lagoon/entrypoints/* in an alphabetical order and then runs `exec` on the given parameter.

if [ -d /lagoon/entrypoints ]; then
  for i in /lagoon/entrypoints/*; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

# If the image provides a native entrypoint that can, or should, be run after the lagoon endpoints are set, it's path can be
# set in the APPEND_NATIVE_ENTRYPOINT variable.
if [ -n "$APPEND_NATIVE_ENTRYPOINT" ] && [ -f $APPEND_NATIVE_ENTRYPOINT ]; then
  echo "running defined endpoint"
  . $APPEND_NATIVE_ENTRYPOINT
fi

exec "$@"
