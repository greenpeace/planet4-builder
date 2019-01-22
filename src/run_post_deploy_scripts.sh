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


echo "Now check the common post deploy scripts and run them as well"

pushd source
git pull https://github.com/greenpeace/planet4-base-fork .

for file in tasks/post-deploy/*; do
    echo ""
    echo "Running the common script : $(basename "$file")"
    echo ""
    HELM_NAMESPACE=$(HELM_NAMESPACE) \
	  HELM_RELEASE=$(HELM_RELEASE) \
	  ./run_bash_script_in_php_pod.sh modify_users.sh "$(shell base64 -w 0 users.json)"
done
