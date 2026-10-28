#!/usr/bin/env bash
set -euo pipefail

if [[ ! -s /config/authorized_keys ]]; then
  echo "missing /config/authorized_keys" >&2
  exit 2
fi

install -d -m 0700 /root/.ssh
install -m 0600 /config/authorized_keys /root/.ssh/authorized_keys
exec "$@"


