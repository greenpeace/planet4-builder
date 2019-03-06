#!/usr/bin/env bash
set -euo pipefail

[ "${APP_ENVIRONMENT}" = "develop" ] && {
  echo "Development environment: skipping database backup"
  exit 0
}

release=${HELM_RELEASE:-$1}

tag=${CIRCLE_TAG:-${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}
tag=$(echo "$tag" |  tr -c '[[:alnum:]]._-' '-' | sed 's/-$//')

echo
echo "Backup release database:"
echo "Release:   $release"
echo "Tag:       $tag"
echo

if ! helm status "${HELM_RELEASE}" | tee release_status.txt
then
  echo "SKIP: Release not yet deployed"
  exit 0
fi

if grep -q "STATUS: FAILED" release_status.txt
then
  echo "SKIP: Release is in a failed state"
  exit 0
fi

namespace=${HELM_NAMESPACE:-${2:-$(grep 'NAMESPACE:' release_status.txt | cut -d' ' -f2 | sed 's/planet4-//' | sed 's/-master$//' | sed 's/-release$//' | xargs)}}

if ! kubectl get namespace "$namespace" > /dev/null
then
  echo "ERROR: Namespace '$namespace' not found."
  exit 1
fi

# Set kubernetes command with namespace
kc="kubectl -n $namespace"

php=$(kubectl get pods --namespace "${namespace}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "app=wordpress-php,release=${release}" \
  -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]
then
  echo "ERROR: PHP pod not found!"
  exit 1
fi

if ! $kc exec "$php" -- wp core is-installed
then
  echo "SKIP: Wordpress is not yet installed"
  exit 0
fi

datestring=$(date -u +"%Y%m%dT%H%M%SZ")
working_dir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename "$0").XXXXXXXXXXXX")
function finish() {
  rm -fr "$working_dir"
}
trap finish EXIT

$kc exec "$php" -- wp db export "backup-$datestring.sql"

pushd "$working_dir" >/dev/null

filename="$release-$tag-$datestring.sql"

$kc cp "$php:backup-$datestring.sql" "$filename"

$kc exec "$php" -- rm -f "$php:backup-$datestring.sql"

gzip "$filename"

bucket="${release}-db-backup"

if ! gsutil ls "gs://$bucket" >/dev/null
then
  echo "Creating bucket: gs://$bucket"
  gsutil mb -p "${GOOGLE_PROJECT_ID:-planet-4-151612}" "gs://$bucket"
  gsutil label ch -l "nro:${APP_HOSTPATH:-undefined}" "gs://${bucket}"
  gsutil label ch -l "environment:${ENVIRONMENT:-development}" "gs://${bucket}"
fi

gsutil cp "$filename.gz" "gs://$bucket/$tag/$filename.gz"

echo
echo "SUCCESS: Database backed up to: gs://$bucket/$tag/$filename.gz"
echo "URL: https://console.cloud.google.com/storage/browser/$bucket/$tag/?project=${GOOGLE_PROJECT_ID:-planet-4-151612}"
echo

popd >/dev/null
sync
