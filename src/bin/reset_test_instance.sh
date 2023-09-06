#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "Check if commit message requires reset"
git clone --depth=1 https://github.com/greenpeace/"${CONTAINER_PREFIX}"
GIT_COMMIT_MSG=$(git --git-dir="${CONTAINER_PREFIX}"/.git log --format=%B -n 1 "$CIRCLE_SHA1")
if [[ $GIT_COMMIT_MSG == *"[RESET]"* && $CONTAINER_PREFIX == *"test-"* ]]; then
  echo "Reset is required"
else
  echo "No Sync required. Exiting."
  exit 0
fi
echo ""

CONTENT_DB_VERSION="0.2.18"
CONTENT_BASE="gs://planet4-default-content/"
CONTENT_DB="planet4-defaultcontent_wordpress-v${CONTENT_DB_VERSION}.sql.gz"
LOCAL_DB="defaultcontent.sql"

GCLOUD_ZONE="us-central1-a"
GCLOUD_CLUSTER="p4-development"
GOOGLE_PROJECT_ID="planet-4-151612"

WP_DB_USERNAME_DC=$(echo "${WP_DB_USERNAME}" | base64 -d)
WP_DB_PASSWORD_DC=$(echo "${WP_DB_PASSWORD}" | base64 -d)
WP_DB_TO_IMPORT_TO=$(yq -r .job_environments.develop_environment.WP_DB_NAME "$CONTAINER_PREFIX"/.circleci/config.yml)
CLOUDSQL_INSTANCE="planet-4-151612:us-central1:p4-develop-k8s"

echo ""
echo "Creating the credential file for mysql"
cat <<EOF >mysql.cnf
[client]
user = ${WP_DB_USERNAME_DC}
password = ${WP_DB_PASSWORD_DC}
host = 127.0.0.1
EOF

echo ""
echo "Get active instance"
INSTANCE=${CONTAINER_PREFIX/planet4-/}
echo "Instance: ${INSTANCE}"
echo ""

echo ""
echo "Connect to dev cloud"
gcloud container clusters get-credentials "${GCLOUD_CLUSTER}" --zone "${GCLOUD_ZONE}" --project "${GOOGLE_PROJECT_ID}"
echo ""

echo ""
echo "Download DB dump"
gsutil cp "${CONTENT_BASE}${CONTENT_DB}" "${LOCAL_DB}.gz"
gunzip "${LOCAL_DB}"
echo ""

echo ""
echo "Configure CloudSQL"
cloud_sql_proxy -instances="${CLOUDSQL_INSTANCE}=tcp:3306" &
sleep 5
echo ""

echo ""
echo "Find the most recent php pod that is in Running status"
POD=$(kubectl get pods --namespace "${INSTANCE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "component=php" \
  -o jsonpath="{.items[-1:].metadata.name}")
echo ""

echo ""
echo "Get instance specific options"
GA_ID=$(kubectl exec -n "$INSTANCE" "$POD" -- wp option pluck galogin ga_clientid)
GA_SECRET=$(kubectl exec -n "$INSTANCE" "$POD" -- wp option pluck galogin ga_clientsecret)
echo ""

echo ""
echo "Sync Stateless bucket"
gsutil rsync -d -r gs://planet4-defaultcontent-stateless-develop gs://"${WP_STATELESS_BUCKET}"
echo ""

echo ""
echo "Importing the DB file"
mysql --defaults-extra-file="mysql.cnf" "${WP_DB_TO_IMPORT_TO}" <"${LOCAL_DB}"
sleep 5
kubectl exec -n "$INSTANCE" "$POD" -- wp cache flush
echo ""

echo ""
echo "Restore paths"
OLD_PATH="www-dev.greenpeace.org/defaultcontent"
NEW_PATH="www-dev.greenpeace.org/${INSTANCE}"
kubectl exec -n "$INSTANCE" "$POD" -- wp search-replace "$OLD_PATH" "$NEW_PATH" --precise --skip-columns=guid
OLD_PATH="https://www.greenpeace.org/static/planet4-defaultcontent-stateless-develop/"
NEW_PATH="https://www.greenpeace.org/static/${CONTAINER_PREFIX}-stateless-develop/"
kubectl exec -n "$INSTANCE" "$POD" -- wp search-replace "$OLD_PATH" "$NEW_PATH" --precise --skip-columns=guid
echo ""

echo ""
echo "Restore instance specific options"
kubectl exec -n "$INSTANCE" "$POD" -- wp option patch update galogin ga_clientid "$GA_ID"
kubectl exec -n "$INSTANCE" "$POD" -- wp option patch update galogin ga_clientsecret "$GA_SECRET"
echo ""

echo ""
echo "Flushing cache"
kubectl exec -n "$INSTANCE" "$POD" -- wp cache flush
echo ""
