#!/usr/bin/env bash
set -ex

FILE=/home/circleci/source/composer.json

if [ ! -z "$MASTER_THEME_BRANCH" ]
then
    echo "Replacing master theme with branch ${MASTER_THEME_BRANCH}"

    FILE=/home/circleci/source/composer.json
    sed -i "s|\"greenpeace\/planet4-master-theme\" : \".*\",|\"greenpeace\/planet4-master-theme\" : \"${MASTER_THEME_BRANCH}\",|g" ${FILE}

    FILE=/home/circleci/merge/composer.json
    sed -i "s|\"greenpeace\/planet4-master-theme\" : \".*\",|\"greenpeace\/planet4-master-theme\" : \"${MASTER_THEME_BRANCH}\",|g" ${FILE}

    echo "And now, delete any cached version of this package"
    rm -rf /home/circleci/source/cache/files/greenpeace/planet4-master-theme

else
    echo "Nothing to replace for the master theme"
fi


echo "DEBUG: We will echo where master theme is defined as what: "
grep -r -H '"greenpeace/planet4-master-theme" :' *