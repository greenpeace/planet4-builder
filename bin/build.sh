#!/usr/bin/env bash
set -eo pipefail

# UTILITY

function usage {
  >&2 echo "Usage: $0 [-l|r|v] [-c <configfile>] ...

Build and test the CircleCI base image.

Options:
  -c    Config file for environment variables, eg:
        $0 -c config
  -l    Perform the CircleCI task locally (requires circlecli)
  -r    Submits a build request to Google Container Builder
  -v    Verbose
"
}

# -----------------------------------------------------------------------------
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
        *  )    usage
                exit 1;;
    esac
done
shift $((OPTIND - 1))

# -----------------------------------------------------------------------------
# CREATE TEMP DIR AND CLEAN ON EXIT
function finish() {
  rm -fr "$TMPDIR"
}
trap finish EXIT

TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

# -----------------------------------------------------------------------------
# OUTPUT HELPERS
wget -q -O ${TMPDIR}/pretty-print.sh https://gist.githubusercontent.com/27Bslash6/ffa9cfb92c25ef27cad2900c74e2f6dc/raw/7142ba210765899f5027d9660998b59b5faa500a/bash-pretty-print.sh
# shellcheck disable=SC1090
. ${TMPDIR}/pretty-print.sh

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

# Setup environment variables
. ${BUILD_DIR}/bin/env.sh

# Rewrite only the variables we want to change
ENVVARS=(
  '${ACK_VERSION}' \
  '${APPLICATION_DESCRIPTION}' \
  '${APPLICATION_NAME}' \
  '${BRANCH_NAME}' \
  '${CIRCLECI_USER}' \
  '${DOCKER_COMPOSE_VERSION}' \
  '${GETTEXT_VERSION}' \
  '${GOOGLE_SDK_VERSION}' \
  '${HELM_VERSION}' \
  '${IMAGE_FROM}' \
  '${IMAGE_MAINTAINER}' \
  '${JUNIT_MERGE_VERSION}' \
  '${NODEJS_VERSION}' \
  '${SHELLCHECK_VERSION}' \
  '${TAP_XUNIT_VERSION}' \
  '${TERRAFORM_VERSION}' \
  '${TERRAGRUNT_VERSION}' \
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
_build "Rewriting Dockerfile from template ..."
echo -e "${DOCKER_BUILD_STRING}\n$(cat ${BUILD_DIR}/src/circleci-base/Dockerfile)" > ${BUILD_DIR}/src/circleci-base/Dockerfile
_build "Rewriting README.md from template ..."
echo -e "$(cat ${BUILD_DIR}/README.md)\nBuild: ${CIRCLE_BUILD_URL:-"(local)"}" > ${BUILD_DIR}/README.md

# Process array of cloudbuild substitutions
function getSubstitutions() {
  local -a arg=($@)
  s="$(printf "%s," "${arg[@]}" )"
  echo "${s%,}"
}

# Cloudbuild.yaml template substitutions
CLOUDBUILD_SUBSTITUTIONS=(
  "_BRANCH_TAG=${BRANCH_NAME//[^a-zA-Z0-9]/-}" \
  "_BUILD_NUMBER=${CIRCLE_BUILD_NUM:-$(git rev-parse --short HEAD)}" \
  "_GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID:-${DEFAULT_GOOGLE_PROJECT_ID}}" \
  "_NAMESPACE=${NAMESPACE:-${DEFAULT_NAMESPACE}}" \
  "_REVISION_TAG=${CIRCLE_TAG:-$(git rev-parse --short HEAD)}" \
)
CLOUDBUILD_SUBSTITUTIONS_STRING=$(getSubstitutions "${CLOUDBUILD_SUBSTITUTIONS[@]}")

# Submit the build
# @todo Implement local build
# $ circlecli build . -e GCLOUD_SERVICE_KEY=$(base64 ~/.config/gcloud/Planet-4-circleci.json)
if [[ "$BUILD_LOCALLY" = 'true' ]]
then
  if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]
  then
    _fatal "GOOGLE_APPLICATION_CREDENTIALS environment variable not set.

Please set GOOGLE_APPLICATION_CREDENTIALS to the path of your GCP service key and try again.
"
  fi

  if [[ $(type -P "circleci") ]]
  then
    _build "Performing build locally ..."
    circleci build . -e "GCLOUD_SERVICE_KEY=$(base64 "${GOOGLE_APPLICATION_CREDENTIALS}")"
  else
    _fatal "ERROR :: circlecli not found in PATH. Please install from https://circleci.com/docs/2.0/local-jobs/"
  fi
fi

if [[ "${BUILD_REMOTELY}" = 'true' ]]
then
  _build "Sending build request to GCR ..."
  # Avoid sending entire .git history as build context to save some time and bandwidth
  # Since git builtin substitutions aren't available unless triggered
  # https://cloud.google.com/container-builder/docs/concepts/build-requests#substitutions
  tar --exclude='.git/' --exclude='.circleci/' -zcf ${TMPDIR}/docker-source.tar.gz .

  time gcloud container builds submit \
    --verbosity=${VERBOSITY:-"warning"} \
    --timeout=10m \
    --config cloudbuild.yaml \
    --substitutions ${CLOUDBUILD_SUBSTITUTIONS_STRING} \
    ${TMPDIR}/docker-source.tar.gz

fi

if [[ -z "$BUILD_LOCALLY" ]] && [[ -z "${BUILD_REMOTELY}" ]]
then
  _notice "No build option specified"
  usage
fi
