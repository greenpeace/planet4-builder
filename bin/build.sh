#!/usr/bin/env bash
set -euo pipefail

# Builds the planet4-circleci:base containers
# Optionally builds locally or on Google's cloud builder service

# UTILITY

function usage() {
  echo >&2 "Usage: $0 [-b|t] [-c <configfile>] ...

Build and test the CircleCI base image.

Options:
  -b    Builds containers
  -t    Generates files from templates
"
}

# -----------------------------------------------------------------------------

# COMMAND LINE OPTIONS

[ -z ${BUILD+x} ] && BUILD=
[ -z ${TEMPLATE+x} ] && TEMPLATE=

OPTIONS=':bt'
while getopts $OPTIONS option; do
  case $option in
    b) BUILD='true' ;;
    t) TEMPLATE='true' ;;
    *)
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

# -----------------------------------------------------------------------------

# CREATE TEMP DIR AND CLEAN ON EXIT

TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

function finish() {
  rm -fr "$TMPDIR"
}
trap finish EXIT

# -----------------------------------------------------------------------------

# OUTPUT HELPERS

[ -f "${TMPDIR}/pretty-print.sh" ] || wget -q -O "${TMPDIR}/pretty-print.sh" https://gist.githubusercontent.com/27Bslash6/ffa9cfb92c25ef27cad2900c74e2f6dc/raw/7142ba210765899f5027d9660998b59b5faa500a/bash-pretty-print.sh
# shellcheck disable=SC1090
. "${TMPDIR}/pretty-print.sh"

# -----------------------------------------------------------------------------

#

[[ ${TEMPLATE} = "true" ]] && {
  # Reads key-value file as function argument, extracts and wraps key with ${..}
  # for use in envsubst file templating
  function get_var_array() {
    set -eu
    local file
    file="$1"
    declare -a var_array
    while IFS=$'\n' read -r line; do
      var_array+=("$line")
    done < <(grep '=' "${file}" | awk -F '=' '{if ($0!="" && $0 !~ /^\s*#/) print $1}' | sed -e "s/^/\"\${/" | sed -e "s/$/}\" \\\\/" | tr -s '}')

    echo "${var_array[@]}"
  }

  # Rewrite only the variables we want to change
  declare -a ENVVARS
  while IFS=$'\n' read -r line; do
    ENVVARS+=("$line")
  done < <(get_var_array "config.default")

  ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
  ENVVARS_STRING="${ENVVARS_STRING%:}"

  envsubst "${ENVVARS_STRING}" <"src/circleci-base/templates/Dockerfile.in" >"src/circleci-base/Dockerfile.tmp"
  envsubst "${ENVVARS_STRING}" <"README.md.in" >"README.md.tmp"

  DOCKER_BUILD_STRING="# greenpeaceinternational/circleci-base:${BUILD_TAG}
# $(echo "${APPLICATION_DESCRIPTION}" | tr -d '"')
# Branch: ${CIRCLE_TAG:-${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}
# Commit: ${CIRCLE_SHA1:-$(git rev-parse HEAD)}
# Build:  ${BUILD_NUM}
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
"

  _build "Rewriting Dockerfile from template ..."
  echo "${DOCKER_BUILD_STRING}
$(cat "src/circleci-base/Dockerfile.tmp")" >"src/circleci-base/Dockerfile"
  rm "src/circleci-base/Dockerfile.tmp"

  _build "Rewriting README.md from template ..."
  echo "$(cat "README.md.tmp")
Build: ${CIRCLE_BUILD_URL:-"(local)"}" >"README.md"
  rm "README.md.tmp"

  # -----------------------------------------------------------------------------
}

# Build container
[[ "$BUILD" = 'true' ]] && {
  time docker build "src/circleci-base" \
    --tag "greenpeaceinternational/circleci-base:${BUILD_NUM}" \
    --tag "greenpeaceinternational/circleci-base:${BUILD_TAG}"

  [[ -n "${BUILD_BRANCH}" ]] && docker tag "greenpeaceinternational/circleci-base:${BUILD_NUM}" "greenpeaceinternational/circleci-base:${BUILD_BRANCH}"
}

if [[ "$BUILD" != "true" ]] && [[ "${TEMPLATE}" != "true" ]]; then
  _notice "No build option specified"
  echo
  usage
fi
