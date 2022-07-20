#!/usr/bin/env bash
set -euo pipefail

function finish() {
  # Stop background jobs
  kill "$(jobs -p)"
}

WP_DB_USERNAME_DC=$(echo "${WP_DB_USERNAME}" | base64 -d)
WP_DB_PASSWORD_DC=$(echo "${WP_DB_PASSWORD}" | base64 -d)
SITE_ENV=$1
CLOUDSQL_INSTANCE=${GOOGLE_PROJECT_ID}:us-central1:${CLOUDSQL_INSTANCE}
export GOOGLE_APPLICATION_CREDENTIALS="/tmp/workspace/src/key.json"
if [ -z ${CIRCLE_TAG+x} ]; then
  SQL_TAG=$(date +%Y-%m-%d)
else
  SQL_TAG=${CIRCLE_TAG}
fi
export SQL_TAG
export GCLOUD_ZONE=us-central1-a

echo ""
echo "We will try to get connected to: ${CLOUDSQL_INSTANCE}"
echo ""

echo ""
echo "Creating the credential file for mysql"
echo ""
cat <<EOF >mysql.cnf
[client]
user = ${WP_DB_USERNAME_DC}
password = ${WP_DB_PASSWORD_DC}
host = 127.0.0.1
EOF

trap finish EXIT
cloud_sql_proxy \
  -instances="${CLOUDSQL_INSTANCE}=tcp:3306" &

echo ""
echo "Creating the credential file for mysql"
echo ""
cat <<EOF >mysql.cnf
[client]
user = ${WP_DB_USERNAME_DC}
password = ${WP_DB_PASSWORD_DC}
host = 127.0.0.1
EOF

mkdir -p content

sleep 2

BUCKET_DESTINATION="gs://${CONTAINER_PREFIX}-source"
MASTER_DB=$(yq -r .job_environments.production_environment.WP_DB_NAME /tmp/workspace/src/.circleci/config.yml)
FILE_TO_IMPORT=${MASTER_DB}-${SQL_TAG}.sql
WP_DB_TO_IMPORT_TO=$(yq -r .job_environments."${SITE_ENV}"_environment.WP_DB_NAME /tmp/workspace/src/.circleci/config.yml)
echo ""
echo "Exporting from $MASTER_DB the file $FILE_TO_IMPORT and importing it to $WP_DB_TO_IMPORT_TO"
echo ""

echo ""
echo "Copying the file from the bucket"
echo ""
gsutil cp "${BUCKET_DESTINATION}/${FILE_TO_IMPORT}.gz" "content/${FILE_TO_IMPORT}.gz"

echo ""
echo "Gunzip the file"
echo ""
gunzip "content/${FILE_TO_IMPORT}.gz"

echo ""
echo "Importing the database to the ${WP_DB_TO_IMPORT_TO} database"
echo ""
mysql --defaults-extra-file="mysql.cnf" "${WP_DB_TO_IMPORT_TO}" <"content/${FILE_TO_IMPORT}"

echo ""
echo "Get connected to gcloud"
echo ""
gcloud container clusters get-credentials "${GCLOUD_CLUSTER}" --zone "${GCLOUD_ZONE}" --project "${GOOGLE_PROJECT_ID}"

echo ""
echo "flushing the redis database"
echo ""
flush_redis.sh

SOURCE_BUCKET="${CONTAINER_PREFIX}-stateless"
echo ""
echo "Actually replacing the contents of the release stateless with the production stateless bucket"
echo "Source bucket: $SOURCE_BUCKET"
echo "Target bucket: $WP_STATELESS_BUCKET"
echo ""
gsutil rsync -d -r gs://"${SOURCE_BUCKET}" gs://"${WP_STATELESS_BUCKET}"

echo ""
echo "Set kubectl command to use the namespace"
echo ""
kc="kubectl -n ${HELM_NAMESPACE}"
echo ""
echo "Find the first php pod in the release ${HELM_RELEASE}"
echo ""
POD=$($kc get pods -l component=php | grep "${HELM_RELEASE}" | head -n1 | cut -d' ' -f1)
echo "Pod:        $POD"
echo

# Full db domain and path replacement
# Check if we are in an pathless environment
if [[ $APP_HOSTPATH == "<nil>" ]]; then
  OLD_PATH=$(yq -r .job_environments.production_environment.APP_HOSTNAME /tmp/workspace/src/.circleci/config.yml)
  NEW_PATH=$(yq -r .job_environments."${SITE_ENV}"_environment.APP_HOSTNAME /tmp/workspace/src/.circleci/config.yml)
else
  OLD_PATH=$(yq -r .job_environments.production_environment.APP_HOSTNAME /tmp/workspace/src/.circleci/config.yml)/$APP_HOSTPATH
  NEW_PATH=$(yq -r .job_environments."${SITE_ENV}"_environment.APP_HOSTNAME /tmp/workspace/src/.circleci/config.yml)/$APP_HOSTPATH
fi
echo "Domain and path replacement."
echo "We will replace $OLD_PATH with $NEW_PATH"
echo
$kc exec "$POD" -- wp search-replace "$OLD_PATH" "$NEW_PATH" --precise --skip-columns=guid
echo

# Stateless domain and path replacement
# Check if this in .org or .ch domain
if [[ "$APP_HOSTNAME" == *"greenpeace.org"* ]]; then
  OLD_PATH="https://www.greenpeace.org/static/${CONTAINER_PREFIX}-stateless/"
  NEW_PATH="https://www.greenpeace.org/static/${CONTAINER_PREFIX}-stateless-${SITE_ENV}/"
elif [[ "$APP_HOSTNAME" == *"greenpeace.ch"* ]]; then
  NEW_DOMAIN=$(yq -r .job_environments."${SITE_ENV}"_environment.APP_HOSTNAME /tmp/workspace/src/.circleci/config.yml)
  OLD_PATH="https://${NEW_DOMAIN}/static/${CONTAINER_PREFIX}-stateless/"
  NEW_PATH="https://www.greenpeace.ch/static/${CONTAINER_PREFIX}-stateless-${SITE_ENV}/"
else
  OLD_PATH="https://storage.googleapis.com/${CONTAINER_PREFIX}-stateless/"
  NEW_PATH="https://storage.googleapis.com/${CONTAINER_PREFIX}-stateless-${SITE_ENV}/"
fi
echo ""
echo "Stateless domain and path replacement."
echo "We will replace the path $OLD_PATH with $NEW_PATH for the images themselves"
echo ""
$kc exec "$POD" -- wp search-replace "$OLD_PATH" "$NEW_PATH" --precise --skip-columns=guid

echo
echo "Discourage search engines from indexing dev/stage sites"
echo
$kc exec "$POD" -- wp option update blog_public 0

if [[ "$APP_ENV" = "development" ]]; then
  echo "Remove GF addons settings"
  # shellcheck disable=SC2046
  $kc exec "$POD" -- wp option delete $(wp option list --search='gravityformsaddon_*_settings' --field=option_name)
fi

echo ""
echo "Flushing cache"
echo ""
$kc exec "$POD" -- wp cache flush
