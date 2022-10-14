#!/bin/bash
set -eo pipefail

# Check if this is runs in the main branch. We use that check to reset the test instance.
# Otherwise it's either a normal PR or just a new commit that doesn't require deployment.
if [[ "$CIRCLE_BRANCH" = "main" ]]; then
  echo true >/tmp/workspace/is_merge_commit
  echo "$CIRCLE_PULL_REQUEST" >/tmp/workspace/pr
else
  if [ -z "$CIRCLE_PULL_REQUEST" ]; then
    echo "No PR found, skipping instance deploy"
    exit 1
  fi
  echo false >/tmp/workspace/is_merge_commit
  echo "$CIRCLE_PULL_REQUEST" >/tmp/workspace/pr
fi
