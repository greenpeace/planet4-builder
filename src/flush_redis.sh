#!/usr/bin/env bash

set -eu

main() {
  redis=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
    --field-selector=status.phase=Running \
    -l "app=redis,role=master,release=${HELM_RELEASE}" \
    -o jsonpath="{.items[0].metadata.name}")

  if [[ -z "$redis" ]]
  then
    >&2 echo "ERROR: redis pod not found in release ${HELM_RELEASE}"
    return 1
  fi
  echo "Flushing redis pod ${redis} in ${HELM_NAMESPACE}..."
  kubectl --namespace "${HELM_NAMESPACE}" exec "$redis" redis-cli flushdb
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
