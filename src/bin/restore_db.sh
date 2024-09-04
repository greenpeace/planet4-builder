#!/usr/bin/env bash
set -euo pipefail

WP_DB_USERNAME_DC=$(echo "${WP_DB_USERNAME}" | base64 -d)
WP_DB_PASSWORD_DC=$(echo "${WP_DB_PASSWORD}" | base64 -d)
CLOUDSQL_INSTANCE=${GOOGLE_PROJECT_ID}:us-central1:${CLOUDSQL_INSTANCE}
export GOOGLE_APPLICATION_CREDENTIALS="/tmp/workspace/src/key.json"

echo
echo "We will try to get connected to: ${CLOUDSQL_INSTANCE}"
echo

echo
echo "Creating the credential file for mysql"
cat <<EOF >mysql.cnf
[client]
user = ${WP_DB_USERNAME_DC}
password = ${WP_DB_PASSWORD_DC}
host = 127.0.0.1
EOF
echo

cloud_sql_proxy \
  -instances="${CLOUDSQL_INSTANCE}=tcp:3306" &

echo
echo "Creating the credential file for mysql"
cat <<EOF >mysql.cnf
[client]
user = ${WP_DB_USERNAME_DC}
password = ${WP_DB_PASSWORD_DC}
host = 127.0.0.1
EOF
echo

echo
echo "Copying the file from the bucket"
BUCKET_SOURCE=gs://${WP_STATELESS_BUCKET}_db_backup
FILE_TO_IMPORT=$(gcloud storage ls -r -l "${BUCKET_SOURCE}/**" | sort -k2 | tail -n 1 | awk '{print $NF}')
echo "${FILE_TO_IMPORT}"
gcloud storage cp "${FILE_TO_IMPORT}" "db-${CIRCLE_TAG}.sql.gz"
echo

echo
echo "Gunzip the file"
gunzip "db-${CIRCLE_TAG}.sql.gz"
echo

echo
echo "Importing the DB file"
mysql --defaults-extra-file="mysql.cnf" "${WP_DB_NAME}" <"db-${CIRCLE_TAG}.sql"
sleep 5
echo
