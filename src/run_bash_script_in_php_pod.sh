#!/usr/bin/env bash
set -euo pipefail

external_script=$1
shift
args=$*

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" --field-selector=status.phase=Running -l "app=wordpress-php,release=${HELM_RELEASE}" -o jsonpath="{.items[0].metadata.name}")

if [[ -z "$php" ]]
then
  >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
fi

if [[ ! -e "$external_script" ]]
then
  >&2 echo "ERROR: file does not exist: '$1'"
fi

kubectl -n "${HELM_NAMESPACE}" cp "$external_script" "$php:/tmp/$external_script"
kubectl -n "${HELM_NAMESPACE}" exec "$php" -- "/tmp/$external_script" "$args"
kubectl -n "${HELM_NAMESPACE}" exec "$php" -- rm "/tmp/$external_script"
