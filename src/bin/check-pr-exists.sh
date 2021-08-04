#!/bin/bash
set -eo pipefail

commit_msg="$1"

# Check if this is a merge commit first, which means this triggered by a merged PR.
# We use that check to reset the test instance.
# Otherwise it's either a normal PR or just a new commit that doesn't require deployment.
if [[ "$commit_msg" =~ ^Merge[[:space:]]pull[[:space:]]request[[:space:]]\#([[:digit:]]+) ]]; then
  echo "https://github.com/greenpeace/${CIRCLE_PROJECT_REPONAME}/pull/${BASH_REMATCH[1]}" >/tmp/workspace/pr
  echo "MERGED PR ID: ${BASH_REMATCH[1]}"
  echo true >/tmp/workspace/is_merge_commit
else
  if [ -z "$CIRCLE_PULL_REQUEST" ]; then
    echo "No PR found, skipping instance deploy"
    exit 1
  fi
  echo false >/tmp/workspace/is_merge_commit
  echo "$CIRCLE_PULL_REQUEST" >/tmp/workspace/pr
fi
