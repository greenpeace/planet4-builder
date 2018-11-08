#!/usr/bin/env bash
set -euo pipefail

release=${1:-${HELM_RELEASE}}
current=$(helm history "$release" --max=1 | tail -1 | awk '{ print $1 }' | xargs)

re='^[0-9]+$'
if ! [[ $current =~ $re ]] ; then
   >&2 echo "ERROR: Revision is not a number: $current"
   exit 1
fi

if [[ $current -eq 1 ]]
then
  >&2 echo "ERROR: $release is first revision, cannot perform helm rollback"
  exit 1
fi

previous=${2:-$((current-1))}
echo "Helm: Rolling back $release to revision $previous"

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
