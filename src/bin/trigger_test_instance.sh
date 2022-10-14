#!/usr/bin/env bash
set -euo pipefail

repo=$1
is_merge_commit=$2

if [ -z "$repo" ]; then
  echo "Repository name required."
  exit 1
fi

instance_repo=planet4-test-$(cat /tmp/workspace/test-instance)

git config --global user.email "${GIT_USER_EMAIL}"
git config --global user.name "CircleCI Bot"
git config --global push.default simple
git config --global url."ssh://git@github.com".insteadOf "https://github.com" || true
mkdir -p ~/.ssh/ && echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >~/.ssh/config

git clone "https://github.com/greenpeace/$instance_repo"

composer_file="$instance_repo/composer-local.json"

get_other_repos=".repositories // [] | map(select( .package.name != \"greenpeace/$repo\" ))"

other_repos=$(jq "$get_other_repos" <"$composer_file")

if [ "$is_merge_commit" == true ]; then
  # If the workflow is running on the main branch, we set the version to the branch that was merged to.
  version="dev-$CIRCLE_BRANCH"
  package_repo=""
else
  version="7"
  zip_url="https://storage.googleapis.com/$(cat /tmp/workspace/zip-path)"
  composer_json=$(jq '{name,type,autoload,extra}' </tmp/workspace/composer.json |
    jq ".version = $version" |
    jq ".dist = {type: \"zip\", url: \"$zip_url\"}")
  package_repo="{type: \"package\", package: $composer_json}"
fi

# This is needed since using cat directly when piping to the same file doesn't work here, resulted in a empty file.
orig_json=$(cat "$composer_file")

echo "$orig_json" |
  jq ".repositories = $other_repos" |
  jq ".repositories += [$package_repo]" |
  jq --tab ".require.\"greenpeace/$repo\" = \"$version\"" >"$composer_file"

git -C "$instance_repo" --no-pager diff

git -C "$instance_repo" add composer-local.json

git -C "$instance_repo" commit --allow-empty \
  -m "${CIRCLE_PULL_REQUEST:-$CIRCLE_PROJECT_REPONAME} at ${CIRCLE_SHA1:0:8}" \
  -m "/unhold $CIRCLE_WORKFLOW_ID"

git -C "$instance_repo" push
