#!/usr/bin/env bash
set -euo pipefail
file="${1:-${HOME}/source/composer.json}"

[ -e "$file" ] || {
  echo >&2 "File not found: $file"
  exit 1
}

if [ "$APP_ENVIRONMENT" == "staging" ]; then
  echo "The APP_ENVIRONMENT is $APP_ENVIRONMENT so we will pin greenpeace repos to their release branches"
  echo "---"
  echo
  for i in $(jq -r '[.require | to_entries[] | select(.key | startswith("greenpeace")) ] | .[] | "\(.key):\(.value)"' "$file"); do
    repo=${i//:*/}
    ver=${i//*:/}
    printf "%s @ %s" "$repo" "$ver"

    release_branch=$(./latest_release_branch.sh "$repo")
    if [ -n "$release_branch" ] && [[ $ver != "dev-$release_branch" ]]; then
      release_branch=dev-${release_branch}
      echo " => $release_branch"
      sed -i'.bckp' "s|\"${repo}\"*\".*\",|\"${repo}\" : \"${release_branch}\",|g" "$file"
    else
      echo
    fi
  done
fi
