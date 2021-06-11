#!/usr/bin/env bash
set -e

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "release=${HELM_RELEASE},component=php" \
  -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]; then
  echo >&2 "ERROR: php pod not found in release ${HELM_RELEASE}"
  exit 1
fi

kubectl -n "${HELM_NAMESPACE}" exec -it "$php" -- bash -c "wp user create p4_test_user p4test+user@greenpeace.org --role=editor --user_pass=${WP_TEST_USER}"
