#!/usr/bin/env bash
set -eo pipefail

# UTILITY

function usage {
  fatal "Usage: $0 [-l|r|v] [-c <configfile>] ...

Build and test artifacts in this repository. By default this script will only
recreate a new Dockerfile from the Dockerfile.in template.  To initiate a build

Options:
  -c    Config file for environment variables, eg:
        $0 -c config
  -l    Perform the CircleCI task locally (requires circlecli)
  -r    Submits a build request to Google Container Builder
  -v    Verbose
"
}

function fatal() {
 >&2 echo -e "ERROR: $1"
 exit 1
}

# COMMAND LINE OPTIONS

OPTIONS=':vc:lr'
while getopts $OPTIONS option
do
    case $option in
        c  )    CONFIG_FILE=$OPTARG;;
        l  )    BUILD_LOCALLY='true';;
        r  )    BUILD_REMOTELY='true';;
        v  )    VERBOSITY='debug'
                set -x;;
        *  )    usage;;
    esac
done
shift $(($OPTIND - 1))

#
#   ----------- NO USER SERVICEABLE PARTS BELOW -----------
#

BUILD_DIR=$(dirname $0)

# CONFIG FILE
# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

DEFAULT_CONFIG_FILE="${BUILD_DIR}/config.default"
if [[ ! -f "${DEFAULT_CONFIG_FILE}" ]]
then
  fatal "ERROR :: Default configuration file not found: ${DEFAULT_CONFIG_FILE}"
fi
# shellcheck source=/dev/null
source ${DEFAULT_CONFIG_FILE}

# Read from custom config file from command line parameter
if [ ! -z "${CONFIG_FILE}" ]; then
  if [ ! -f "${CONFIG_FILE}" ]; then
    fatal "ERROR: Custom config file not found: ${CONFIG_FILE}"
  fi

  echo "Reading config from: ${CONFIG_FILE}"

  # https://github.com/koalaman/shellcheck/wiki/SC1090
  # shellcheck source=/dev/null
  source ${CONFIG_FILE}
fi

# Envsubst variable consolidation
ACK_VERSION="${ACK_VERSION:-${DEFAULT_ACK_VERSION}}"
APPLICATION_NAME=${APPLICATION_NAME:-${DEFAULT_APPLICATION_NAME}}
BASE_IMAGE="${BASE_IMAGE:-${DEFAULT_BASE_IMAGE}}"
BASE_NAMESPACE="${BASE_NAMESPACE:-${DEFAULT_BASE_NAMESPACE}}"
BASE_TAG="${BASE_TAG:-${DEFAULT_BASE_TAG}}"
DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION:-${DEFAULT_DOCKER_COMPOSE_VERSION}}"
GOOGLE_SDK_VERSION="${GOOGLE_SDK_VERSION:-${DEFAULT_GOOGLE_SDK_VERSION}}"
IMAGE_FROM="${BASE_NAMESPACE}/${BASE_IMAGE}:${BASE_TAG}"
IMAGE_MAINTAINER="${MAINTAINER:-${DEFAULT_MAINTAINER}}"

# Process array of cloudbuild substitutions
function getSubstitutions() {
  local -a arg=($@)
  s="$(printf "%s," "${arg[@]}" )"
  echo "${s%,}"
}

if [[ "$1" = "test" ]]
then
  BUILD_LOCALLY=true
fi

# Rewrite only the cloudbuild variables we want to change
ENVVARS=(
  '${ACK_VERSION}' \
  '${DOCKER_COMPOSE_VERSION}' \
  '${GOOGLE_PROJECT_ID}' \
  '${GOOGLE_SDK_VERSION}' \
  '${IMAGE_FROM}' \
  '${IMAGE_MAINTAINER}' \
  '${UPSTREAM_TAG}' \
)

ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
ENVVARS_STRING="${ENVVARS_STRING%:}"

envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/circleci-base/templates/Dockerfile.in > ${BUILD_DIR}/circleci-base/Dockerfile
# envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/templates/README.md.in > ${BUILD_DIR}/README.md

BUILD_STRING="# ${APPLICATION_NAME}
# Build:  ${CIRCLE_BUILD_NUM:-"test-$(git rev-parse --abbrev-ref HEAD)"}
# URL:    ${CIRCLE_BUILD_URL:-"(local)"}
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
"

echo -e "$BUILD_STRING\n$(cat ${BUILD_DIR}/circleci-base/Dockerfile)" > ${BUILD_DIR}/circleci-base/Dockerfile

# Cloudbuild.yaml template substitutions
CLOUDBUILD_SUBSTITUTIONS=(
  "_BRANCH_TAG=${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}" \
  "_BUILD_NUMBER=${CIRCLE_BUILD_NUM:-$(git rev-parse --short HEAD)}" \
  "_GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID:-${DEFAULT_GOOGLE_PROJECT_ID}}" \
  "_NAMESPACE=${NAMESPACE:-${DEFAULT_NAMESPACE}}" \
  "_REVISION_TAG=${CIRCLE_TAG:-$(git rev-parse --short HEAD)}" \
)
CLOUDBUILD_SUBSTITUTIONS_STRING=$(getSubstitutions "${CLOUDBUILD_SUBSTITUTIONS[@]}")

# Check if we're running on CircleCI
if [[ ! -z "${CIRCLECI}" ]]
then
  # Expect gcloud to be configured under the home directory
  GCLOUD=${HOME}/google-cloud-sdk/bin/gcloud
else
  # Hope for the best
  GCLOUD=gcloud
fi

# Submit the build
# @todo Implement local build
# $ circlecli build . -e GCLOUD_SERVICE_KEY=$(base64 ~/.config/gcloud/Planet-4-circleci.json)
if [[ "$BUILD_LOCALLY" = 'true' ]]
then
  if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]
  then
    fatal "GOOGLE_APPLICATION_CREDENTIALS environment variable not set.

Please set GOOGLE_APPLICATION_CREDENTIALS to the path of your GCP service key and try again.
"
  fi

  if [[ $(type -P "circleci") ]]
  then
    circleci build . -e "GCLOUD_SERVICE_KEY=$(base64 "${GOOGLE_APPLICATION_CREDENTIALS}")"
  else
    fatal "ERROR :: circlecli not found in PATH. Please install from https://circleci.com/docs/2.0/local-jobs/"
  fi
fi

if [[ "${BUILD_REMOTELY}" = 'true' ]]
then
  # Avoid sending entire .git history as build context to save some time and bandwidth
  # Since git builtin substitutions aren't available unless triggered
  # https://cloud.google.com/container-builder/docs/concepts/build-requests#substitutions
  TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")
  tar --exclude='.git/' --exclude='.circleci/' -zcf ${TMPDIR}/docker-source.tar.gz .

  time ${GCLOUD} container builds submit \
    --verbosity=${VERBOSITY:-"warning"} \
    --timeout=10m \
    --config cloudbuild.yaml \
    --substitutions ${CLOUDBUILD_SUBSTITUTIONS_STRING} \
    ${TMPDIR}/docker-source.tar.gz

    rm -fr ${TMPDIR}

fi
