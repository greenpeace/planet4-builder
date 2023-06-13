#!/usr/bin/env bash
set -euo pipefail

# First parameter is name of script to execute in the Openresty pod
external_script=$1
base_external_script=$(basename "$external_script")
shift

if [[ ! -e "$external_script" ]]; then
  echo >&2 "ERROR: file does not exist: '$1'"
  exit 1
fi

pods=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
  --field-selector=status.phase=Running \
  -l "release=${HELM_RELEASE}" \
  -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}" | grep openresty)

if [[ -z "$pods" ]]; then
  echo >&2 "ERROR: openresty pod not found in release ${HELM_RELEASE}"
  exit 1
fi

for openresty in $pods; do
  kubectl -n "${HELM_NAMESPACE}" cp "$external_script" "$openresty:/tmp/$base_external_script"
  kubectl -n "${HELM_NAMESPACE}" exec "$openresty" -- "/tmp/$base_external_script" "$*"
  kubectl -n "${HELM_NAMESPACE}" exec "$openresty" -- rm "/tmp/$base_external_script"
done
