#!/usr/bin/env bash
set -euo pipefail

function finish() {
  # Stop background jobs
  kill "$(jobs -p)"
}

WP_DB_USERNAME_DC=$(echo "${WP_DB_USERNAME}" | base64 -d)
WP_DB_PASSWORD_DC=$(echo "${WP_DB_PASSWORD}" | base64 -d)
BUCKET_DESTINATION=gs://${CONTAINER_PREFIX}-source
export GOOGLE_APPLICATION_CREDENTIALS="/tmp/workspace/src/key.json"

if [ -z ${CIRCLE_TAG+x} ]; then
  SQL_TAG=$(date +%Y-%m-%d)
else
  SQL_TAG=${CIRCLE_TAG}
fi
export SQL_TAG

echo ""
echo "We will try to get connected to: ${GOOGLE_PROJECT_ID}:us-central1:${CLOUDSQL_INSTANCE}"
echo ""

trap finish EXIT
cloud_sql_proxy \
  -instances="${GOOGLE_PROJECT_ID}:us-central1:${CLOUDSQL_INSTANCE}=tcp:3306" &

mkdir -p content

sleep 2

echo ""
echo "mysqldump ${WP_DB_NAME} > content/${WP_DB_NAME}-${SQL_TAG}.sql ..."
echo ""
mysqldump -v --column-statistics=0 --set-gtid-purged=OFF \
  -u "$WP_DB_USERNAME_DC" \
  -p"$WP_DB_PASSWORD_DC" \
  -h 127.0.0.1 \
  "${WP_DB_NAME}" >"content/${WP_DB_NAME}-${SQL_TAG}.sql"

echo ""
echo "gzip ..."
echo ""
gzip --verbose --best "content/${WP_DB_NAME}-${SQL_TAG}.sql"
gzip --test "content/${WP_DB_NAME}-${SQL_TAG}.sql.gz"

echo ""
echo "Checking if bucket exists"
echo ""
if ! gcloud storage ls "${BUCKET_DESTINATION}/"; then
  echo "Bucket does not exist, attempting to create it"
  gcloud storage buckets create "${BUCKET_DESTINATION}/"
  echo "And now we will apply labels"
  gcloud storage buckets update "gs://${BUCKET_DESTINATION}" \
    --update-labels=nro="${APP_HOSTNAME}",environment="${ENVIRONMENT}"
fi

echo ""
echo "uploading to ${BUCKET_DESTINATION}/..."
echo ""
gcloud storage cp "content/${WP_DB_NAME}-${SQL_TAG}.sql.gz" "${BUCKET_DESTINATION}/"

gcloud storage ls "${BUCKET_DESTINATION}/"
