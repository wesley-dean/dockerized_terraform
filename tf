#!/usr/bin/env bash

function _tf() {
  image="$1"
  shift

  aws_credential_mount=""

  if [ -f "${HOME}/.aws/credentials" ] ; then
    aws_credential_mount="--volume ${HOME}/.aws/credentials:/root/.aws/credentials"
  fi

  docker run \
    --rm \
    --tty \
    --interactive \
    --volume "${PROJECT_ROOT}:${WORKDIR}" \
    "$aws_credential_mount" \
    --workdir "${WORKDIR}" \
    "${image}" \
  "$@" \
| sed -Ee "s|$WORKDIR|$PROJECT_ROOT|g"
}

TFIMAGE="${TFIMATE:-hashicorp/terraform:light}"
CLEANUPIMAGE="${CLEANUPIMAGE:-busybox}"
WORKDIR="${WORKDIR:-/workdir}"
TIMESTAMPFILE="${TIMESTAMPFILE:-.rightnow.txt}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

uid="${uid:-$(id -u)}"
gid="${gid:-$(id -g)}"

touch "${PROJECT_ROOT}/${TIMESTAMPFILE}"

_tf "$TFIMAGE" "$@"
_tf "$CLEANUPIMAGE" find . -newer "$WORKDIR/$TIMESTAMPFILE" -exec chown "$uid:$gid" {} \;

rm -f "${PROJECT_ROOT}/${TIMESTAMPFILE}"
