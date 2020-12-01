#!/usr/bin/env bash
# Keep in mind that errexit does not work inside if statements
set -euo pipefail
# use the same options for subshells
export SHELLOPTS

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
  (
    set -x
    "$@"
  )
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

upload_sks() {
  keyid="${1}"
  status "Uploading key to the SKS pool..."
  run gpg --keyserver hkps://hkps.pool.sks-keyservers.net --send-keys "$keyid"
  status "Uploaded key to the SKS pool."
}

upload_openpgp() {
  keyid="${1}"
  status "Uploading key to keys.openpgp.org..."
  (
    set -x
    gpg --export "$keyid" | curl -T - https://keys.openpgp.org
  )
  status "Key has been uploaded to keys.openpgp.org. Please visit the verification link above."
}

lint() {
  keyid="${1}"
  status "Checking key..."
  gpg --export-secret-keys "$keyid" | hokey lint
  status "Done. If you see any red parts above, please update your key."
}

case "${1:-}" in
  '')
    usage
    exit 1
    ;;
  -h* | --help)
    usage
    ;;
  *)
    extend "$@"
    upload_sks "${1}" || echo2 "Uploading to SKS keyservers failed."
    upload_openpgp "${1}" || echo2 "Uploading to OpenPGP keyserver failed."
    lint "${1}" || echo2 "Linting failed."
    ;;
esac
