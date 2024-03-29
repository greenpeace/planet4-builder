#!/usr/bin/env bash
set -uo pipefail

# shellcheck disable=SC1091
. lib/retry.sh

function install() {

  if helm3 upgrade --install --force --wait --timeout 300s "${HELM_RELEASE}" \
    --namespace "${HELM_NAMESPACE}" \
    --values "$HOME"/var/values.yaml \
    --values "$HOME"/var/secrets.yaml \
    --version "${CHART_VERSION}" \
    --create-namespace \
    p4/wordpress 2>&1 | tee -a helm_output.txt; then
    echo "SUCCESS: Deployed release $HELM_RELEASE"
    return 0
  fi
  echo "FAILURE: Could not deploy release $HELM_RELEASE"

  return 1
}

echo "Deploying $HELM_RELEASE in $HELM_NAMESPACE with chart version $CHART_VERSION..."
echo

# Create Helm deploy secrets file from environment
# FIXME: generate this in ramfs
envsubst <"$HOME"/var/secrets.yaml.in >"$HOME"/var/secrets.yaml

# Create values file
envsubst <"$HOME"/var/values.yaml.in >"$HOME"/var/values.yaml
cat "$HOME"/var/values.yaml

TIMEOUT=10 retry install && exit 0

echo >&2 "ERROR: Helm release ${HELM_RELEASE} failed to deploy"

helm_rollback.sh

exit 1
