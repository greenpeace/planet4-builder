#!/usr/bin/env bash
set -ex

FILE=/home/circleci/build/source/composer-local.json

if [ ! -z "$MASTER_THEME_BRANCH" ]
then
    echo "Replacing master theme with branch ${MASTER_THEME_BRANCH}"
    sed -i "s|\"greenpeace\/planet4-master-theme\" : \".*\",|\"greenpeace\/planet4-master-theme\" : \"${MASTER_THEME_BRANCH}\",|g" ${FILE}
else
    echo "Nothing to replace for the master theme"
fi
