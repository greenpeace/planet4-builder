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

# Check if ElasticPress is active
if kubectl --namespace "${HELM_NAMESPACE}" exec "$php" -- wp plugin is-active elasticpress; then
  # Try WPML sync, fall back to regular sync if WPML fails
  kubectl --namespace "${HELM_NAMESPACE}" exec "$php" -- sh -c 'yes | wp wpml_elasticpress sync --setup' ||
    kubectl --namespace "${HELM_NAMESPACE}" exec "$php" -- sh -c 'wp elasticpress sync --setup --yes --force'
else
  echo "ElasticPress plugin is not active. Skipping sync."
fi
