#!/usr/bin/env bash
set -euo pipefail

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "app=wordpress-php,release=${HELM_RELEASE}" \
  -o jsonpath="{.items[-1:].metadata.name}")


for file in $(kubectl -n "${HELM_NAMESPACE}" exec $php -- ls ./post_deploy_scripts); do
    echo ""
    echo "Running the local script : $(basename "$file")"
    echo ""
    kubectl -n "${HELM_NAMESPACE}" exec "$php" -- bash "post_deploy_scripts/$file"
done

