#!/usr/bin/env bash
set -eu

function finish {
  # Stop background jobs
  kill "$(jobs -p)"
}

WP_DB_USERNAME_DC=$(echo "${WP_DB_USERNAME}" | base64 -d)
WP_DB_PASSWORD_DC=$(echo "${WP_DB_PASSWORD}" | base64 -d)
WP_STATELESS_KEY_DC=$(echo "${WP_STATELESS_KEY}" | base64 -d)
CLOUDSQL_INSTANCE=${GOOGLE_PROJECT_ID}:us-central1:${CLOUDSQL_INSTANCE}
BUCKET_DESTINATION=gs://${CONTAINER_PREFIX}-source
export GOOGLE_APPLICATION_CREDENTIALS="/tmp/workspace/src/key.json"
export SQL_TAG=$CIRCLE_TAG

echo ""
echo "We will try to get connected to: ${CLOUDSQL_INSTANCE}"
echo ""

trap finish EXIT
cloud_sql_proxy \
  -instances="${CLOUDSQL_INSTANCE}=tcp:3306" &

mkdir -p content

sleep 2

echo ""
echo "mysqldump ${WP_DB_NAME} > content/${WP_DB_NAME}-${SQL_TAG}.sql ..."
echo ""
mysqldump -v \
  -u "$WP_DB_USERNAME_DC" \
  -p"$WP_DB_PASSWORD_DC" \
  -h 127.0.0.1 \
  ${WP_DB_NAME} > "content/${WP_DB_NAME}-${SQL_TAG}.sql"

echo ""
echo "gzip ..."
echo ""
gzip --verbose --best "content/${WP_DB_NAME}-${SQL_TAG}.sql"
gzip --test "content/${WP_DB_NAME}-${SQL_TAG}.sql.gz"

echo ""
echo "Checking if bucket exists"
echo ""
if ! gsutil ls "${BUCKET_DESTINATION}/"
then
  echo "Bucket does not exist, attempting to create it"
  gsutil mb "${BUCKET_DESTINATION}/";
  echo "And now we will apply labels"
  gsutil label ch -l "nro:${APP_HOSTPATH}" "${BUCKET_DESTINATION}"
  gsutil label ch -l "environment:${ENVIRONMENT}" "${BUCKET_DESTINATION}"
fi


echo ""
echo "uploading to ${BUCKET_DESTINATION}/..."
echo ""
gsutil cp "content/${WP_DB_NAME}-${SQL_TAG}.sql.gz" "${BUCKET_DESTINATION}/"

gsutil ls "${BUCKET_DESTINATION}/"
