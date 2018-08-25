#!/usr/bin/env bash
set -eu

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" -l "app=wordpress-php,release=${HELM_RELEASE}" -o jsonpath="{.items[0].metadata.name}")

if [[ -z "$php" ]]
then
  >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
fi

kubectl exec -n ${HELM_NAMESPACE} $php -- wp plugin activate --all
