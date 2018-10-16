#!/usr/bin/env bash
set -euo pipefail

#
# Find the first php pod in the release
#
pod=$(kubectl get pods --namespace "${HELM_NAMESPACE}" --field-selector=status.phase=Running -l "app=wordpress-php,release=${HELM_RELEASE}" -o jsonpath="{.items[0].metadata.name}")

if [[ -z "$pod" ]]
then
  >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
fi

redis_servicename=$(helm status ${HELM_RELEASE} | grep Service -A 10 | grep redis-master | head -n1 | cut -d' ' -f1)

echo "Pod:        $pod"
echo ""
echo "Option:     rt_wp_nginx_helper_options"
echo "Key:        redis_hostname"
echo "Value:      $redis_servicename"
echo ""

kubectl -n ${HELM_NAMESPACE} exec $pod -- wp option patch update rt_wp_nginx_helper_options redis_hostname $redis_servicename
