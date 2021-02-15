#!/usr/bin/env bash
set -euo pipefail

# First parameter is name of script to execute in the PHP pod
external_script=$1
base_external_script=$(basename "$external_script")
shift

if [[ ! -e "$external_script" ]]; then
  echo >&2 "ERROR: file does not exist: '$1'"
  exit 1
fi

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "release=${HELM_RELEASE},component=php" \
  -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]; then
  echo >&2 "ERROR: php pod not found in release ${HELM_RELEASE}"
  exit 1
fi

kubectl -n "${HELM_NAMESPACE}" cp "$external_script" "$php:/tmp/$base_external_script"
kubectl -n "${HELM_NAMESPACE}" exec "$php" -- "/tmp/$base_external_script" "$*"
kubectl -n "${HELM_NAMESPACE}" exec "$php" -- rm "/tmp/$base_external_script"
