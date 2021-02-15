#!/usr/bin/env bash
set -uo pipefail

# shellcheck disable=SC1091
. lib/retry.sh

function install() {

  if helm upgrade --install --force --wait --timeout 300 "${HELM_RELEASE}" \
    --namespace "${HELM_NAMESPACE}" \
    --values values.yaml \
    --values secrets.yaml \
    --version "${CHART_VERSION}" \
    p4/wordpress 2>&1 | tee -a helm_output.txt; then
    echo "SUCCESS: Deployed release $HELM_RELEASE"
    return 0
  fi
  echo "FAILURE: Could not deploy release $HELM_RELEASE"

  if grep -q "kind Service with the name \"${HELM_RELEASE}-redis-headless\" already exists in the cluster and wasn't defined in the previous release" helm_output.txt; then
    kubectl -n "${HELM_NAMESPACE}" delete svc "${HELM_RELEASE}"-redis-headless
  fi

  return 1
}

echo "Deploying $HELM_RELEASE in $HELM_NAMESPACE with chart version $CHART_VERSION..."
echo

# Create Helm deploy secrets file from environment
# FIXME: generate this in ramfs
envsubst <secrets.yaml.in >secrets.yaml

# Create values file
envsubst <values.yaml.in >values.yaml
cat values.yaml

TIMEOUT=10 retry install && exit 0

echo >&2 "ERROR: Helm release ${HELM_RELEASE} failed to deploy"

./helm_rollback.sh

exit 1
