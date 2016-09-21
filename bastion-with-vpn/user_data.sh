#!/usr/bin/env bash
# NOTE: This is just an example of how one might create a file `foo` on
# the remote host.

set -e
cat <<EOF > foo
Host *
  IdentityFile ~/.ssh/key.pem
  User ubuntu
EOF
