#!/usr/bin/env bash
# shellcheck disable=2034
set -a

VERSION_REGEX="v?[[:digit:]]+\\.[[:digit:]]+"

[ -z "${BUILD_IMAGE+x}" ] && BUILD_IMAGE=gcr.io/planet-4-151612/circleci-base
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
  image="$1"
  shift
  args=("$@")
  cmd=$(echo "${args[0]}")
  suffix=${OUT:-out}
  logdir=${LOGS:-${BATS_TEST_DIRNAME}/logs}
  [ ! -d "$logdir" ] && mkdir -p "${logdir}"
  outfile="${logdir}/${cmd}.${suffix}"
  echo " --- ${args[*]} --- $(date)" >> "$outfile"
  docker run --rm -ti "${image}" "${args[@]}" | tee -a "$outfile"
}
