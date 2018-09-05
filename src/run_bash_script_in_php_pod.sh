#!/usr/bin/env bash
set -eu

external_script=$1

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" -l "app=wordpress-php,release=${HELM_RELEASE}" -o jsonpath="{.items[0].metadata.name}")

if [[ -z "$php" ]]
then
  >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
fi

kubectl cp $external_script ${HELM_NAMESPACE}/$php:/app/bin/$external_script
kubectl -n ${HELM_NAMESPACE} -p $php exec bash /app/bin/$external_script
kubectl -n ${HELM_NAMESPACE} -p $php exec rm /app/bin/$external_script
