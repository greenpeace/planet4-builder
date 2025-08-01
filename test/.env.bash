#!/usr/bin/env bash
# shellcheck disable=2034
set -a

VERSION_REGEX="?[[:digit:]]+\\.[[:digit:]]+"

[ -z "${BUILD_IMAGE+x}" ] && BUILD_IMAGE=greenpeaceinternational/circleci-base
[ -z "${BUILD_TAG+x}" ] && BUILD_TAG=build-$(uname -n | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9._-]/-/g')

BATS_IMAGE="${BUILD_IMAGE}:${BUILD_TAG}"

FOLDER=${CIRCLE_PROJECT_REPONAME:-$(basename "$(git rev-parse --show-toplevel)")}

function setup {
  set -e
  docker images | grep -Eq "^${BUILD_IMAGE}\\s+${BUILD_TAG}" || {
    >&2 echo "ERROR: Image not found: ${BATS_IMAGE}"
    >&2 echo "Perhaps run make first?"
    exit 1
  }
}
#
# function teardown {
#   store_output
# }

function finish {
  { set +ex; } 2>/dev/null
}
trap finish EXIT

function warning {
  >&2 echo "WARNING: $1"
}

function error {
  fatal "$1"
}

function fatal {
  >&2 echo "ERROR: $1"
  exit 1
}

function run_docker_binary() {
  set -euo pipefail

  local image="$1"
  shift
  local args=("$@")
  local cmd="${args[0]}"
  local suffix=${OUT:-out}
  local logdir=${LOGS:-${BATS_TEST_DIRNAME}/logs}
  local outfile="${logdir}/${cmd}.${suffix}"

  [ ! -d "$logdir" ] && mkdir -p "${logdir}"

  echo "--- $(date)" >> "$outfile"
  echo "$ ${args[*]}" >> "$outfile"

  docker run --rm -ti "${image}" bash -c "eval ${args[*]}" | tee -a "$outfile"

  echo >> "$outfile"
}
