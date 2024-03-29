#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. lib/retry.sh

release=${1:-${HELM_RELEASE}}
helm3 history -n "${HELM_NAMESPACE}" "$release" --max=10

helm3 status -n "${HELM_NAMESPACE}" "$release" >helm_get_release.txt
current=$(grep '^REVISION:' helm_get_release.txt | cut -d' ' -f2)

re='^[0-9]+$'
if ! [[ $current =~ $re ]]; then
  echo >&2 "ERROR: Revision is not a number: $current"
  exit 1
fi

helm3 status -n "${HELM_NAMESPACE}" "$release" | tee helm_release_status.txt

if [[ $current -eq 1 ]]; then
  echo >&2 "ERROR: $release is first revision, cannot perform helm rollback"
  exit 1
fi

status=$(grep '^STATUS:' helm_release_status.txt | cut -d' ' -f2)
echo "Release #current of $release is in state: $status"

# Find last good deployment
previous=${2:-$((current - 1))}
while [[ $previous -gt 0 ]]; do
  revision_status=$(helm3 status -n "${HELM_NAMESPACE}" "$release" --revision "$previous" | grep '^STATUS:' | cut -d' ' -f2 | xargs)
  [[ "$revision_status" == "superseded" || "$revision_status" == "deployed" ]] && break
  previous=$((previous - 1))
done

# Nothing found, exit with error
[[ $previous -lt 1 ]] && echo >&2 "ERROR: No good releases to roll back to!" && exit 1

# Success
function rollback() {
  echo "Rolling back $release to revision: $previous"

  # Perform rollback
  if helm3 rollback -n "${HELM_NAMESPACE}" "$release" "$previous"; then
    echo "SUCCESS: Release $release now at revision: $previous"
    return 0
  fi

  echo >&2 "ERROR: Failed to rollback $release to revision: $previous"
  return 1
}

retry rollback && exit 0

echo >&2 "ERROR: Failed during rollback"

helm3 status -n "${HELM_NAMESPACE}" "$release"

exit 1
