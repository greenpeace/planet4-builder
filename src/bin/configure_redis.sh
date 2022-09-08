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
    -l "release=${HELM_RELEASE},component=php" \
    -o jsonpath="{.items[-1:].metadata.name}")

  if [[ -z "$pod" ]]; then
    echo >&2 "ERROR: php pod not found in release ${HELM_RELEASE}"
    return 1
  fi

  redis_service=$(
    kubectl get service --namespace "${HELM_NAMESPACE}" \
      -l "app.kubernetes.io/name=redis,app.kubernetes.io/component=master,app.kubernetes.io/instance=${HELM_RELEASE}" \
      -o jsonpath="{.items[0].metadata.name}" ||
      kubectl get service --namespace "${HELM_NAMESPACE}" \
        -l "app=redis,release=${HELM_RELEASE}" \
        -o jsonpath="{.items[0].metadata.name}"
  )

  if [[ -z "$redis_service" ]]; then
    echo >&2 "ERROR: redis service not found in release ${HELM_RELEASE}"
    return 1
  fi

  echo "Pod:        $pod"
  echo ""
  echo "Option:     rt_wp_nginx_helper_options"
  echo "Key:        redis_hostname"
  echo "Value:      $redis_service"
  echo ""

  if kubectl -n "${HELM_NAMESPACE}" exec "$pod" -- \
    wp option patch update rt_wp_nginx_helper_options redis_hostname "$redis_service"; then
    return 0
  fi

  return $?

}

retry main && exit 0

echo >&2 "FAILED"
exit 1
