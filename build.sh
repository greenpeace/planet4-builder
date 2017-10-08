#!/usr/bin/env bash
set -eo pipefail

if [ "$1" = "-v" ]; then
  set -x
  VERBOSITY=debug
fi

# Cloudbuild.yaml template substitutions
SUBSTITUTIONS=(
  "_BUILD_NUMBER=${CIRCLE_BUILD_NUM:-"test"}" \
  "_GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID:-"planet-4-151612"}" \
  "_REVISION_TAG=${CIRCLE_TAG:-$(git rev-parse --short HEAD)}" \
  "_BRANCH_TAG=${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}" \
)

#
#   ----------- NO USER SERVICEABLE PARTS BELOW -----------
#

if [[ "$1" = "test" ]]
then
  BUILD_LOCALLY=true
fi

function getSubstitutions() {
  local -a arg=($@)
  SUBSTITUTIONS_PROCESSOR="$(printf "%s," "${arg[@]}" )"
  echo -e "${SUBSTITUTIONS_PROCESSOR%,}"
}
SUBSTITUTIONS_STRING=$(getSubstitutions "${SUBSTITUTIONS[@]}")

# Avoid sending entire .git history as build context to save some time and bandwidth
# Since git builtin substitutions aren't available unless triggered
# https://cloud.google.com/container-builder/docs/concepts/build-requests#substitutions
TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")
tar --exclude='.git/' --exclude='.circleci/' -zcf ${TMPDIR}/docker-source.tar.gz .

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
if [[ "$BUILD_LOCALLY" = 'true' ]]
then
  if [[ -x circlecli ]]
  then
    circlecli
  else
    fatal "ERROR :: circlecli not found"
  fi
fi

time ${GCLOUD} container builds submit \
  --verbosity=${VERBOSITY:-"warning"} \
  --timeout=10m \
  --config cloudbuild.yaml \
  --substitutions ${SUBSTITUTIONS_STRING} \
  ${TMPDIR}/docker-source.tar.gz

rm -fr ${TMPDIR}
