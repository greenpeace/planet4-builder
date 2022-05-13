#!/usr/bin/env bash
set -ex

GCLOUD_ZONE="us-central1-a"

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

SYNC_DISABLED_FLAG=$(kubectl --namespace "${HELM_NAMESPACE}" exec "$php" -- wp option pluck planet4_features disable_data_sync || true)

if [[ $SYNC_DISABLED_FLAG == "on" ]]; then
  echo "Data sync is disabled in Admin Panel"
  exit 1
fi
