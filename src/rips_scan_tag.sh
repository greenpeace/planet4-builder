#!/usr/bin/env bash

TAG_NAME="$(curl -s https://api.github.com/repos/greenpeace/${RIPS_SCAN_REPO}/tags | jq -r '.[0].name')"
TAG_COMMIT="$(curl -s https://api.github.com/repos/greenpeace/${RIPS_SCAN_REPO}/tags | jq -r '.[0].commit.sha')"

APPLICATION_ID=${RIPS_APPLICATION_ID}

echo "Downloading zip archive for tag: ${TAG_NAME}"

wget https://github.com/greenpeace/planet4-master-theme/archive/${TAG_COMMIT}.zip

wget https://github.com/rips/rips-cli/releases/download/1.2.1/rips-cli.phar -O ./rips-cli
chmod 755 ./rips-cli

./rips-cli rips:scan:start -a ${RIPS_APPLICATION_ID} -p ./${TAG_COMMIT}.zip
