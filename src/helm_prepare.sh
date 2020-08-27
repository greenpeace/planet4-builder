#!/usr/bin/env bash
set -eu

release_exists=$(helm list -q | grep -w "${HELM_RELEASE}" | xargs)

if [[ -z "$release_exists" ]]; then
  echo "Helm: ${HELM_RELEASE} does not exist: first deploy"
  exit 0
fi

release_status=$(helm status "${HELM_RELEASE}" -o json | jq '.info.status.code' | xargs)

if [[ $release_status = "1" ]]; then
  echo "Helm: ${HELM_RELEASE} is in a good state"
  exit 0
fi

echo "Helm: ${HELM_RELEASE} is in a failed state, rolling back."

./helm_rollback.sh
