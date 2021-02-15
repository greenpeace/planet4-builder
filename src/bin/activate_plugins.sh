#!/usr/bin/env bash
set -eu

[[ $FORCE_ACTIVATE_PLUGINS == 'true ' ]] || exit 0

# shellcheck disable=SC1091
. lib/retry.sh

main() {
  php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
    --sort-by=.metadata.creationTimestamp \
    --field-selector=status.phase=Running \
    -l "release=${HELM_RELEASE},component=php" \
    -o jsonpath="{.items[-1:].metadata.name}")

  if [[ -z "$php" ]]; then
    echo >&2 "ERROR: php pod not found in release ${HELM_RELEASE}"
  fi

  if kubectl exec -n "${HELM_NAMESPACE}" "$php" -- wp plugin activate --all; then
    return 0
  fi

  return $?
}

retry main && exit 0

echo >&2 "FAILED"
exit 1
