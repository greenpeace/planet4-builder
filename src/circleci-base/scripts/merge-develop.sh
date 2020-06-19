#!/usr/bin/env bash
set -euo pipefail

# Description: Automatically merge develop branch to master on each commit

GIT_COMMIT_MESSAGE=$(git --git-dir=/tmp/workspace/src/.git log --format=%B -n 1 "$CIRCLE_SHA1")
if [[ $GIT_COMMIT_MESSAGE == *"[DEV]"* ]]; then
  echo "Not merging. There a DEV prefix"
  exit 0
fi

git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"
git config merge.ours.driver true

commit_message=":robot: ${2:-Merge develop to master}"

# Ensure master branch is up to date with origin
git checkout master
git reset --hard origin/master

# Merge develop into master, with strategy ours
git merge --strategy-option=ours --no-ff --no-edit develop -m "$commit_message"
git push origin master

exit 0
