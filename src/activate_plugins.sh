#!/usr/bin/env bash
set -eu

# shellcheck disable=SC1091
. lib/retry.sh

main() {
  php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
    --sort-by=.metadata.creationTimestamp \
    --field-selector=status.phase=Running \
    -l "app=wordpress-php,release=${HELM_RELEASE}" \
    -o jsonpath="{.items[-1:].metadata.name}")

  if [[ -z "$php" ]]
  then
    >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
  fi

  if kubectl exec -n "${HELM_NAMESPACE}" "$php" -- wp plugin activate --all
  then
    return 0
  fi

  return $?
}

retry main && exit 0

>&2 echo "FAILED"
exit 1
