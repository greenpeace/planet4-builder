#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. lib/retry.sh

release=${1:-${HELM_RELEASE}}
helm history "$release" --max=10

helm get "$release" > helm_get_release.txt
current=$(grep '^REVISION:' helm_get_release.txt | cut -d' ' -f2)

re='^[0-9]+$'
if ! [[ $current =~ $re ]] ; then
   >&2 echo "ERROR: Revision is not a number: $current"
   exit 1
fi

helm status "$release" | tee helm_release_status.txt

if [[ $current -eq 1 ]]
then
  >&2 echo "ERROR: $release is first revision, cannot perform helm rollback"
  exit 1
fi

status=$(grep '^STATUS:' helm_release_status.txt | cut -d' ' -f2)
echo "Release #current of $release is in state: $status"

# Find last good deployment
previous=${2:-$(( current - 1 ))}
while [[ $previous -gt 0 ]]
do
  [[ $(helm status "$release" --revision "$previous" | grep '^STATUS:' | cut -d' ' -f2 | xargs) == "SUPERSEDED"  ]] && break
  previous=$(( previous - 1 ))
done

# Nothing found, exit with error
[[ $previous -lt 1 ]] && >&2 echo "ERROR: No good releases to roll back to!" && exit 1

# Success
function rollback() {
  echo "Rolling back $release to revision: $previous"

  # Perform rollback
  if helm rollback "$release" "$previous"
  then
    echo "SUCCESS: Release $release now at revision: $previous"
    TYPE="Helm Rollback" \
    EXTRA_TEXT="\`\`\`
    History:
    $(helm history "${HELM_RELEASE}" --max=5)
    \`\`\`" \
    notify-job-success.sh

    return 0
  fi

  >&2 echo "ERROR: Failed to rollback $release to revision: $previous"
  return 1
}

retry rollback && exit 0

>&2 echo "ERROR: Failed during rollback"
helm status "$release
"
TYPE="Helm Rollback" \
EXTRA_TEXT="\`\`\`
History:
$(helm history "${HELM_RELEASE}" --max=5)
\`\`\`" \
notify-job-failure.sh

exit 1
