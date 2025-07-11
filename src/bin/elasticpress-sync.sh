#!/usr/bin/env bash
set -eu

GCLOUD_ZONE=us-central1-a

gcloud container clusters get-credentials "${GCLOUD_CLUSTER}" \
  --zone "${GCLOUD_ZONE}" \
  --project "${GOOGLE_PROJECT_ID}"

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "release=${HELM_RELEASE},component=php" \
  -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]; then
  echo "ERROR: PHP pod not found!"
  exit 1
fi

kubectl --namespace "${HELM_NAMESPACE}" exec "$php" -- sh -c 'yes | wp wpml_elasticpress sync --setup' \
  || kubectl --namespace "${HELM_NAMESPACE}" exec "$php" -- sh -c 'wp elasticpress sync --setup --yes'
