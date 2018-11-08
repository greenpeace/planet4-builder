#!/usr/bin/env bash
set -euo pipefail

# First parameter is name of script to execute in the PHP pod
external_script=$1
shift

if [[ ! -e "$external_script" ]]
then
  >&2 echo "ERROR: file does not exist: '$1'"
  exit 1
fi

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "app=wordpress-php,release=${HELM_RELEASE}" \
  -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]
then
  >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
  exit 1
fi

kubectl -n "${HELM_NAMESPACE}" cp "$external_script" "$php:/tmp/$external_script"
kubectl -n "${HELM_NAMESPACE}" exec "$php" -- "/tmp/$external_script" "$*"
kubectl -n "${HELM_NAMESPACE}" exec "$php" -- rm "/tmp/$external_script"
