#!/bin/sh

# Setting $PATH in a Dockerfile could be overwritten again like it happens in 
# /etc/profile of alpine Images.

add_to_PATH () {
  for d; do
    case ":$PATH:" in
      *":$d:"*) :;;
      *) PATH=$d:$PATH;;
    esac
  done
}

add_to_PATH /home/.composer/vendor/bin
