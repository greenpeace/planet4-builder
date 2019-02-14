#!/usr/bin/env bash
set -ex

files=(
  "${HOME}/source/composer.json"
  "${HOME}/source/composer-local.json"
  "${HOME}/merge/composer.json"
  "${HOME}/merge/composer-local.json"
)

if [ -n "${MASTER_THEME_BRANCH}" ]
then
  echo "Replacing master theme with branch ${MASTER_THEME_BRANCH}"

  for f in "${files[@]}"
  do
    if [ -e "$f" ]
    then
      echo " - $f"
      sed -i "s|\"greenpeace\\/planet4-master-theme\" : \".*\",|\"greenpeace\\/planet4-master-theme\" : \"${MASTER_THEME_BRANCH}\",|g" "${f}"
    fi
  done

  echo "And now, delete any cached version of this package"
  rm -rf "${HOME}/source/cache/files/greenpeace/planet4-master-theme"

else
  echo "Nothing to replace for the master theme"
fi

echo "DEBUG: We will echo where master theme is defined as what: "
grep -r -H '"greenpeace/planet4-master-theme" :' ./*
