#!/usr/bin/env bash
set -euo pipefail
file="${1:-${HOME}/source/composer.json}"

if [ "$APP_ENVIRONMENT" == "staging" ]
then
  echo "The APP_ENVIRONMENT is $APP_ENVIRONMENT so we will pin greenpeace repos to their release branches"
  for i in $(jq -r '[.require | to_entries[] | select(.key | startswith("greenpeace")) ] | .[] | "\(.key):\(.value)"' "$file")
  do
    repo=${i//:*}
    ver=${i//*:}
    release_branch=$(./latest_release_branch.sh "$repo")
    if [ -n "$release_branch" ]
    then
      echo "The repo is $repo"
      echo "The ver is $ver"
      release_branch=dev-${release_branch}
      echo "The release branch is $release_branch"
      sed -i'.bckp' "s|\"${repo}\"*\".*\",|\"${repo}\" : \"${release_branch}\",|g" "$file"
    fi
  done
fi
