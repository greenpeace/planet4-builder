#!/usr/bin/env bash
# shellcheck disable=SC1091

set -euo pipefail

. lib/retry.sh

#
# Find the youngest php pod in the release
#
main() {
  pod=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
    --sort-by=.metadata.creationTimestamp \
    --field-selector=status.phase=Running \
    -l "app=wordpress-php,release=${HELM_RELEASE}" \
    -o jsonpath="{.items[-1:].metadata.name}")

  if [[ -z "$pod" ]]
  then
    >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
    return 1
  fi

  redis_service=$(kubectl get service --namespace "${HELM_NAMESPACE}" \
    -l "app=redis,release=${HELM_RELEASE}" \
    -o jsonpath="{.items[0].metadata.name}")


  if [[ -z "$redis_service" ]]
  then
    >&2 echo "ERROR: redis service not found in release ${HELM_RELEASE}"
    return 1
  fi

  echo "Pod:        $pod"
  echo ""
  echo "Option:     rt_wp_nginx_helper_options"
  echo "Key:        redis_hostname"
  echo "Value:      $redis_service"
  echo ""

  if kubectl -n "${HELM_NAMESPACE}" exec "$pod" -- \
    wp option patch update rt_wp_nginx_helper_options redis_hostname "$redis_service"
  then
    return 0
  fi

  return $?

}

retry main && exit 0

>&2 echo "FAILED"
exit 1
