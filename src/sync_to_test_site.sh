#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "Check if commit message requires Sync"
GIT_COMMIT_MSG=$(git --git-dir=/tmp/workspace/src/.git log --format=%B -n 1 "$CIRCLE_SHA1")
if [[ $GIT_COMMIT_MSG == *"[SYNC]"* ]]
then
    echo "Sync is required"
else
    echo "No Sync required. Exiting."
    exit 0
fi
echo ""

FILE="/tmp/workspace/src/composer-local.json"

NRO=$(jq -r .data_from "$FILE")

GCLOUD_ZONE="us-central1-a"
GCLOUD_CLUSTER_PROD="planet4-production"
GCLOUD_CLUSTER_DEV="p4-development"
GOOGLE_PROJECT_ID_PROD="planet4-production"
GOOGLE_PROJECT_ID_DEV="planet-4-151612"

echo ""
echo "Get active instance"
INSTANCE=${CONTAINER_PREFIX/planet4-test-/}
echo "Instance: ${INSTANCE}"
echo ""

echo ""
echo "Get connected to prod cloud"
echo ""
gcloud container clusters get-credentials "${GCLOUD_CLUSTER_PROD}" --zone "${GCLOUD_ZONE}" --project "${GOOGLE_PROJECT_ID_PROD}"

echo ""
echo "Set kubectl command to use the namespace"
echo ""
kc="kubectl -n ${NRO}"

echo ""
echo "Find the first php pod in the NRO ${NRO}"
echo ""
POD=$($kc get pods -n "${NRO}" -l component=php | grep master | head -n1 | cut -d' ' -f1)

echo ""
echo "Generate the db dump"
echo ""
DB=$($kc exec "${POD}" -- wp db export --tables=wp_commentmeta,wp_comments,wp_postmeta,wp_posts,wp_termmeta,wp_terms,wp_term_relationships,wp_term_taxonomy --add-drop-table | cut -d' ' -f4 | sed -e "s/'\.//" -e "s/'//")
$kc exec "${POD}" -- wp option get planet4_options --format=json > options.json
FRONTPAGE=$($kc exec "${POD}" -- wp option get page_on_front)

echo ""
echo "Copy it locally"
echo ""
$kc cp "${POD}":"${DB}" data.sql
$kc exec "${POD}" -- rm "${DB}"

echo ""
echo "Get connected to dev cloud"
echo ""
gcloud container clusters get-credentials "${GCLOUD_CLUSTER_DEV}" --zone "${GCLOUD_ZONE}" --project "${GOOGLE_PROJECT_ID_DEV}"

echo ""
echo "Set kubectl command to use the namespace"
echo ""
kc="kubectl -n ${HELM_NAMESPACE}"

echo ""
echo "Find the first php pod in the instance ${INSTANCE}"
echo ""
POD=$($kc get pods -l component=php | grep "${INSTANCE}" | head -n1 | cut -d' ' -f1)
echo "Pod: ${POD}"

echo ""
echo "Copying the file inside the pod"
echo ""
$kc cp data.sql develop/"${POD}":data.sql

echo ""
echo "Importing the db file"
echo ""
$kc exec "${POD}" -- wp db import data.sql
$kc exec "${POD}" -- wp option delete planet4_options
$kc exec -i "${POD}" -- wp option add planet4_options --format=json < options.json
$kc exec "${POD}" -- wp option update page_on_front "${FRONTPAGE}"
$kc exec "${POD}" -- rm data.sql

echo ""
echo "Flushing cache"
echo ""
$kc exec "${POD}" -- wp cache flush
