#!/usr/bin/env bash
set -uxo pipefail

# env | sort

helm upgrade --install --force --wait --timeout 300 "${HELM_RELEASE}" \
  --namespace "${HELM_NAMESPACE}" \
  --values secrets.yaml \
  --set dbDatabase="${WP_DB_NAME}" \
  --set environment="${APP_ENVIRONMENT}" \
  --set exim.image.tag="${INFRA_VERSION}" \
  --set hostname="${APP_HOSTNAME}" \
  --set hostpath="${APP_HOSTPATH}" \
  --set newrelic.appname="${NEWRELIC_APPNAME}" \
  --set openresty.image.pullPolicy="${PULL_POLICY}" \
  --set openresty.image.repository="${OPENRESTY_IMAGE}" \
  --set openresty.image.tag="${BUILD_TAG}" \
  --set pagespeed.enabled="${PAGESPEED_ENABLED}" \
  --set php.image.pullPolicy="${PULL_POLICY}" \
  --set php.image.repository="${PHP_IMAGE}" \
  --set php.image.tag="${BUILD_TAG}" \
  --set php.minReplicaCount="${PHP_MIN_REPLICA_COUNT}" \
  --set php.maxReplicaCount="${PHP_MAX_REPLICA_COUNT}" \
  --set openresty.minReplicaCount="${OPENRESTY_MIN_REPLICA_COUNT}" \
  --set openresty.maxReplicaCount="${OPENRESTY_MAX_REPLICA_COUNT}" \
  --set sqlproxy.cloudsql.instances[0].instance="${CLOUDSQL_INSTANCE}" \
  --set sqlproxy.cloudsql.instances[0].project="${GOOGLE_PROJECT_ID}" \
  --set sqlproxy.cloudsql.instances[0].region="${GCLOUD_REGION}" \
  --set sqlproxy.cloudsql.instances[0].port="3306" \
  --set wp.siteUrl="${APP_HOSTNAME}/${APP_HOSTPATH}" \
  --set wp.stateless.bucket="${WP_STATELESS_BUCKET}" \
  p4-helm-charts/wordpress 2>&1 | tee helm_output.txt

if [[ $? -ne 0 ]]
then
  echo "ERROR: Helm release ${HELM_RELEASE} failed to deploy"
  TYPE="Helm Deployment" EXTRA_TEXT="\`\`\`
History:
$(helm history "${HELM_RELEASE}" --max=5)

Build:
$(cat helm_output.txt)
\`\`\`" "${HOME}/scripts/notify-job-failure.sh"

exit 1
fi
