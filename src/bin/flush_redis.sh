#!/usr/bin/env bash
set -eu

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
source="${BASH_SOURCE[0]}"
while [[ -L "$source" ]]; do # resolve $source until the file is no longer a symlink
  dir="$(cd -P "$(dirname "$source")" && pwd)"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
FLUSH_REDIS_DIR="$(cd -P "$(dirname "$source")" && pwd)"

# shellcheck disable=SC1090
. "${FLUSH_REDIS_DIR}/../lib/retry.sh"

function flush() {
  redis=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
    --field-selector=status.phase=Running \
    -l "app=redis,role=master,release=${HELM_RELEASE}" \
    -o jsonpath="{.items[0].metadata.name}")

  if [[ -z "$redis" ]]; then
    echo >&2 "ERROR: redis pod not found in release ${HELM_RELEASE}"
    return 1
  fi
  echo "Flushing redis pod ${redis} in ${HELM_NAMESPACE}..."
  kubectl --namespace "${HELM_NAMESPACE}" exec "$redis" -- redis-cli flushdb
}

retry flush && exit 0

echo >&2 "FAILED"
exit 1
