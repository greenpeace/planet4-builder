#!/usr/bin/env bash
set -euo pipefail

release=${1:-${HELM_RELEASE}}
helm history "$release" --max=10

helm get "$release" > helm_get_release.txt
current=$(grep '^RELEASE:' helm_get_release.txt | cut -d' ' -f2)

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

# Find last good deployment to roll back to
previous=${2:-$((current-1))}
while [[ $previous -gt 0 ]]
do
  [[ $(helm status "$release" | grep '^STATUS:' | cut -d' ' -f2 | xargs) == "SUPERSEDED"  ]] && break
  previous=${2:-$((current-1))}
done

[[ $previous -lt 1 ]] && >&2 echo "ERROR: No good releases to roll back to!" && exit 1

echo "Helm: Rolling back $release to revision: $previous"

if helm rollback "$release" "$previous"
then
  helm history "$release" --max=10

  TYPE="Helm Rollback" \
  EXTRA_TEXT="\`\`\`
  History:
  $(helm history "${HELM_RELEASE}" --max=5)
  \`\`\`" \
  notify-job-success.sh

  exit 0
fi

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
