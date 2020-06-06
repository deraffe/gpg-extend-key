#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "${BASH_SOURCE[0]} keyid [extension period]"
}

echo2() {
  echo "$@" >&2
}

status() {
  echo2 "$@"
}

run() {
  echo2 "+ $*"
  "$@"
}

extend() {
  keyid="${1}"
  extension="${2:-1y}"
  status "Setting expiration of main key..."
  run gpg --quick-set-expire "$keyid" "$extension"
  status "Setting expiration of subkeys..."
  run gpg --quick-set-expire "$keyid" "$extension" '*'
  status "Done."
}

case "$1" in
  '')
    usage
    exit 1
    ;;
  -h* | --help)
    usage
    ;;
  *)
    extend "$@"
    ;;
esac
