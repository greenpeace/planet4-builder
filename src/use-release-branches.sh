#!/usr/bin/env bash
set -euo pipefail

for i in $(jq -r '[.require | to_entries[] | select(.key | startswith("greenpeace")) ] | .[] | "\(.key):\(.value)"' composer.json)
do
  repo=${i//:*}
  ver=${i//*:}
  release_branch=$(latest-release-branch.sh "$repo")
  if [ -n "$release_branch" ]
  then
    echo "The repo is $repo"
    echo "The ver is $ver"
    release_branch=dev-${release_branch}
    echo "The release branch is $release_branch"
    sed -i'.bckp' "s|\"${repo}\"*\".*\",|\"${repo}\" : \"${release_branch}\",|g" composer.json
  fi
done
