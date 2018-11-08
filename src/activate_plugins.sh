#!/usr/bin/env bash
set -eu


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

i=0
retry=3
while [[ $i -lt $retry ]]
do
  main && exit 0
  i=$((i+1))
  echo "Retry: $i/$retry"
done

>&2 echo "FAILED"
exit 1
