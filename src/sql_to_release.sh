#!/usr/bin/env bash
set -eu

function finish {
  # Stop background jobs
  kill "$(jobs -p)"
}

WP_DB_USERNAME_DC=$(echo "${WP_DB_USERNAME}" | base64 -d)
WP_DB_PASSWORD_DC=$(echo "${WP_DB_PASSWORD}" | base64 -d)
WP_STATELESS_KEY_DC=$(echo "${WP_STATELESS_KEY}" | base64 -d)
CLOUDSQL_INSTANCE=planet4-production:us-central1:planet4-prod
export GOOGLE_APPLICATION_CREDENTIALS="/tmp/workspace/src/key.json"
export SQL_TAG=$CIRCLE_TAG
export GCLOUD_ZONE=us-central1-a

echo ""
echo "Creating the credential files for mysql"
echo ""
printf "[client]\n user = ${WP_DB_USERNAME_DC}\n password = ${WP_DB_PASSWORD_DC}\n host = 127.0.0.1" > mysql.cnf


trap finish EXIT

cloud_sql_proxy \
  -instances="${CLOUDSQL_INSTANCE}=tcp:3306" &

mkdir -p content

sleep 2

export BUCKET_DESTINATION="gs://${CONTAINER_PREFIX}-source"
export FILE_TO_IMPORT=${WP_DB_NAME_PREFIX}_master-${SQL_TAG}.sql
export WP_DB_TO_IMPORT_TO=${WP_DB_NAME_PREFIX}_release

echo ""
echo "Copying the file from the container"
echo ""
gsutil cp "${BUCKET_DESTINATION}/${FILE_TO_IMPORT}.gz" "content/${FILE_TO_IMPORT}.gz"

echo ""
echo "Gunzip the file"
echo ""
gunzip "content/${FILE_TO_IMPORT}.gz"

echo ""
echo "Importing the database to the ${WP_DB_TO_IMPORT_TO} database"
echo ""
mysql --defaults-extra-file="mysql.cnf" "${WP_DB_TO_IMPORT_TO}" < "content/${FILE_TO_IMPORT}"

echo ""
echo "Get connected to gcloud"
echo ""
gcloud container clusters get-credentials ${GCLOUD_CLUSTER} --zone ${GCLOUD_ZONE} --project ${GOOGLE_PROJECT_ID}


echo ""
echo "flushing the redis database"
echo ""
/home/circleci/flush_redis.sh

SOURCE_BUCKET="${CONTAINER_PREFIX}-stateless"
echo ""
echo "--- We are missing a step here."
echo "Actually replacing the contents of the release stateless with the production stateless bucket"
echo "Source bucket: $SOURCE_BUCKET"
echo "Target bucket: $WP_STATELESS_BUCKET"
echo ""
gsutil rsync -d -r gs://${SOURCE_BUCKET} gs://${WP_STATELESS_BUCKET}


echo ""
echo "Set kubectl command to use the namespace"
echo ""
kc="kubectl -n ${HELM_NAMESPACE}"
echo ""
echo "Find the first php pod in the release ${HELM_RELEASE}"
echo ""
POD=$($kc get pods -l component=php | grep ${HELM_RELEASE} | head -n1 | cut -d' ' -f1)
echo "Pod:        $POD"

OLD_PATH="https://storage.googleapis.com/${CONTAINER_PREFIX}-stateless/"
NEW_PATH="https://storage.googleapis.com/${CONTAINER_PREFIX}-stateless-release/"
echo ""
echo "Replacing the path $OLD_PATH with $NEW_PATH for the images themselves"
echo ""
$kc exec $POD -- wp search-replace $OLD_PATH $NEW_PATH --precise --skip-columns=guid
