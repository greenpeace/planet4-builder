#!/usr/bin/env bash
set -euo pipefail

[[ ${APP_ENVIRONMENT} =~ production ]] || {
  echo "Non-prod environment: skipping database backup"
  exit 0
}

release=${HELM_RELEASE:-$1}

tag=${CIRCLE_TAG:-${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}
tag=$(echo "$tag" | tr -c '[[:alnum:]]._-' '-' | sed 's/-$//')

echo
echo "Backup release database:"
echo "Release:   $release"
echo "Tag:       $tag"
echo

namespace=$(helm3 list -A -o json | jq --arg release "$release" 'map(select(.name == $release)) | .[0].namespace' | tr -d '"')

if ! helm3 status -n "$namespace" "${HELM_RELEASE}" | tee release_status.txt; then
  echo "SKIP: Release not yet deployed"
  exit 0
fi

grep -Eq "STATUS: deployed" release_status.txt || {
  echo "SKIP: Release is not in a stable state"
  exit 0
}

if ! kubectl get namespace "$namespace" >/dev/null; then
  echo "ERROR: Namespace '$namespace' not found."
  exit 1
fi

# Set kubernetes command with namespace
kc="kubectl -n $namespace"

php=$(kubectl get pods --namespace "${namespace}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "release=${release},component=php" \
  -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]; then
  echo "ERROR: PHP pod not found!"
  exit 1
fi

if ! $kc exec "$php" -- wp core is-installed; then
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

if ! gcloud storage ls "gs://$bucket" >/dev/null; then
  echo "Creating bucket: gs://$bucket"
  gcloud storage buckets create --project "${GOOGLE_PROJECT_ID:-planet-4-151612}" "gs://$bucket"
  gcloud storage buckets update "gs://${bucket}" \
    --update-labels=nro="${APP_HOSTPATH:-undefined}",environment="${ENVIRONMENT:-development}"
fi

gcloud storage cp "$filename.gz" "gs://$bucket/$tag/$filename.gz"

echo
echo "SUCCESS: Database backed up to: gs://$bucket/$tag/$filename.gz"
echo "URL: https://console.cloud.google.com/storage/browser/$bucket/$tag/?project=${GOOGLE_PROJECT_ID:-planet-4-151612}"
echo

popd >/dev/null
sync
