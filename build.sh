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
        c  )    # shellcheck disable=SC2034
                CONFIG_FILE=$OPTARG;;
        l  )    BUILD_LOCALLY='true';;
        r  )    BUILD_REMOTELY='true';;
        v  )    VERBOSITY='debug'
                set -x;;
        *  )    usage;;
    esac
done
shift $((OPTIND - 1))

#
#   ----------- NO USER SERVICEABLE PARTS BELOW -----------
#

BUILD_DIR=$(dirname $0)

# Setup environment variables
. ./bin/env.sh

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
  '${BRANCH_NAME}' \
  '${DOCKER_COMPOSE_VERSION}' \
  '${GOOGLE_SDK_VERSION}' \
  '${IMAGE_FROM}' \
  '${IMAGE_MAINTAINER}' \
)

ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
ENVVARS_STRING="${ENVVARS_STRING%:}"

envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/src/circleci-base/templates/Dockerfile.in > ${BUILD_DIR}/src/circleci-base/Dockerfile
envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/README.md.in > ${BUILD_DIR}/README.md

DOCKER_BUILD_STRING="# ${APPLICATION_NAME}
# Branch: ${BRANCH_NAME}
# Commit: ${CIRCLE_SHA1:-$(git rev-parse HEAD)}
# Build:  ${CIRCLE_BUILD_URL:-"(local)"}
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
"

echo -e "${DOCKER_BUILD_STRING}\n$(cat ${BUILD_DIR}/src/circleci-base/Dockerfile)" > ${BUILD_DIR}/src/circleci-base/Dockerfile
echo -e "$(cat ${BUILD_DIR}/README.md)\nBuild: ${CIRCLE_BUILD_URL:-"(local)"}" > ${BUILD_DIR}/README.md

# Cloudbuild.yaml template substitutions
CLOUDBUILD_SUBSTITUTIONS=(
  "_BRANCH_TAG=${BRANCH_NAME//[^a-zA-Z0-9]/-}" \
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
