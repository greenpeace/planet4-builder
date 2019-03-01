#!/usr/bin/env bash
set -ex

files=(
  "${HOME}/source/composer.json"
  "${HOME}/source/composer-local.json"
  "${HOME}/merge/composer.json"
  "${HOME}/merge/composer-local.json"
)

branches=(
  "MASTER_THEME_BRANCH"
  "PLUGIN_BLOCKS_BRANCH"
  "PLUGIN_ENGAGINGNETWORKS_BRANCH"
)

echo "rewrite_app_repos"

for branch in "${branches[@]}"
do
  reponame=$( echo "${branch%_*}" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')

  if [ -n "${!branch}" ] ; then

    echo "Replacing ${reponame} with branch ${!branch}"

    for f in "${files[@]}"
    do
      if [ -e "$f" ]
      then
        echo " - $f"
        sed -i "s|\"greenpeace\\/planet4-${reponame}\" : \".*\",|\"greenpeace\\/planet4-${reponame}\" : \"${!branch}\",|g" "${f}"
      fi
    done

    echo "And now, delete any cached version of this package"
    rm -rf "${HOME}/source/cache/files/greenpeace/planet4-master-theme"

  else
    echo "Nothing to replace for the ${reponame}"
  fi
done

echo "DEBUG: We will echo where master theme is defined as what: "
grep -r -H '"greenpeace/planet4-master-theme" :' ./*

