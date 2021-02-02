#!/bin/sh
set -e

# If we there is an ssh key injected via lagoon and kubernetes, we use that
if [ -f /var/run/secrets/lagoon/sshkey/ssh-privatekey ]; then
  cp -f /var/run/secrets/lagoon/sshkey/ssh-privatekey /home/.ssh/key
# If there is an env variable SSH_PRIVATE_KEY we use that
elif [ ! -z "$SSH_PRIVATE_KEY" ]; then
  echo -e "$SSH_PRIVATE_KEY" > /home/.ssh/key
# If there is an env variable LAGOON_SSH_PRIVATE_KEY we use that
elif [ ! -z "$LAGOON_SSH_PRIVATE_KEY" ]; then
  echo -e "$LAGOON_SSH_PRIVATE_KEY" > /home/.ssh/key
fi

if [ -f /home/.ssh/key ]; then
  # add a new line to the key. OpenSSH is very picky that keys are always end with a newline
  echo >> /home/.ssh/key
  # Fix permissions of SSH key
  chmod 600 /home/.ssh/key
fi

# If we are not root, remove "  IdentityFile /home/.ssh/lagoon_cli.key" from the /etc/ssh/ssh_config.
# `/home/.ssh/lagoon_cli.key` is only accessible by root and used during docker builds, during runtime
# we are not running as root and therefore can never access this file, we're removing it from the ssh_config
# which will not cause ssh_config to use it and throw any errors.
if [ ! "$(id -u)" -eq 0 ]; then
  TMPFILE=$(mktemp -p /tmp passwd.XXXXXX)
  sed 's/ IdentityFile \/home\/\.ssh\/lagoon_cli\.key//' /etc/ssh/ssh_config > "$TMPFILE"
  cat "$TMPFILE" > /etc/ssh/ssh_config
  rm "$TMPFILE"
fi
