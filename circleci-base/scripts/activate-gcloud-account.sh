#!/usr/bin/env sh
set -ex

if [ -z "${GCLOUD_SERVICE_KEY}" ]; then
  >&2 echo "ERROR :: environment variable GCLOUD_SERVICE_KEY not set"
  exit 1
fi

if [ -z "${GOOGLE_PROJECT_ID}" ]; then
  >&2 echo "ERROR :: environment variable GOOGLE_PROJECT_ID not set"
  exit 1
fi

# Update gcloud sdk components
${HOME}/google-cloud-sdk/bin/gcloud --quiet components update
# Decode base64-encoded service key json
echo "${GCLOUD_SERVICE_KEY}" | base64 --decode -i > ${HOME}/gcloud-service-key.json
# Configure project
${HOME}/google-cloud-sdk/bin/gcloud config set project ${GOOGLE_PROJECT_ID}
# Authneticate
${HOME}/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json
