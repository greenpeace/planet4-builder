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

orig_json=$(cat "$composer_file")

# If this is a merge commit fully reset the composer file and exit
if [ "$is_merge_commit" == true ]; then
  echo "$orig_json" |
    jq "del(.repositories)" |
    jq --tab ".require.\"greenpeace/planet4-master-theme\" = \"dev-main\"" >"$composer_file"

  git -C "$instance_repo" --no-pager diff
  git -C "$instance_repo" add composer-local.json

  git -C "$instance_repo" commit \
    -m "[RESET] Reset instance" \
    -m "Merged PR: ${CIRCLE_PULL_REQUEST:-$CIRCLE_PROJECT_REPONAME}"

  git -C "$instance_repo" push
  exit 0
fi

version="7"
zip_url="https://storage.googleapis.com/$(cat /tmp/workspace/zip-path)"
composer_json=$(jq '{name,type,autoload,extra}' </tmp/workspace/composer.json |
  jq ".version = $version" |
  jq ".dist = {type: \"zip\", url: \"$zip_url\"}")
package_repo="{type: \"package\", package: $composer_json}"

# Pick all other repos to clear
get_other_repos=".repositories // [] | map(select( .package.name != \"greenpeace/$repo\" ))"
other_repos=$(jq "$get_other_repos" <"$composer_file")

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
