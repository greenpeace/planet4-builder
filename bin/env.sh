#!/usr/bin/env bash
# shellcheck disable=SC2034
set -ao pipefail
# -----------------------------------------------------------------------------
# SET BUILD_DIR FROM REAL PATH
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  # if $source was a relative symlink, we need to resolve it relative to the
  # path where the symlink file was located
  [[ $source != /* ]] && source="$dir/$source"
done
BUILD_DIR="$( cd -P "$( dirname "$source" )/.." && pwd )"
# -----------------------------------------------------------------------------
# CONFIG FILE
# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?
DEFAULT_CONFIG_FILE="${BUILD_DIR}/config.default"

if [[ ! -f "${DEFAULT_CONFIG_FILE}" ]]
then
  _fatal "ERROR :: Default configuration file not found: ${DEFAULT_CONFIG_FILE}"
fi

# shellcheck source=config.default
. "${DEFAULT_CONFIG_FILE}"

# Read custom config file
if [ ! -z "${CONFIG_FILE}" ]; then
  if [ ! -f "${CONFIG_FILE}" ]; then
    _fatal "ERROR: Custom config file not found: ${CONFIG_FILE}"
  fi

  _build "Reading config from: ${CONFIG_FILE}"

  # https://github.com/koalaman/shellcheck/wiki/SC1090
  # shellcheck source=/dev/null
  . "${CONFIG_FILE}"
fi

# Envsubst and cloudbuild.yaml variable consolidation

BRANCH_NAME="${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
IMAGE_FROM="${BASE_NAMESPACE}/${BASE_IMAGE}:${BASE_TAG}"
