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
  set -x
  "$@"
  set +x
}

extend() {
  keyid="${1}"
  extension="${2:-1y}"
  status "Setting expiration of main key..."
  run gpg --quick-set-expire "$keyid" "$extension"
  status "Setting expiration of subkeys..."
  run gpg --quick-set-expire "$keyid" "$extension" '*'
  status "Key has been extended."
}

upload() {
  keyid="${1}"
  status "Uploading key..."
  set -x
  gpg --export "$keyid" | curl -T - https://keys.openpgp.org
  set +x
  status "Key has been uploaded. Please visit the verification link above."
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
    upload "$1"
    ;;
esac
