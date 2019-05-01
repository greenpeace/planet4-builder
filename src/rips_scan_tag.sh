#!/usr/bin/env bash
set -euo pipefail

# The application ID is required
RIPS_APPLICATION_ID=$1

# Default organisation is 'greenpeace'
ORG=${2:-greenpeace}

# Default repository is current repo
REPO=${3:-$CIRCLE_PROJECT_REPONAME}

ZIPBALL_URL=$(curl -s "https://api.github.com/repos/${ORG}/${REPO}/tags" | jq -r '.[0].zipball_url')
wget "${ZIPBALL_URL}" -O "${REPO}".zip

wget https://github.com/rips/rips-cli/releases/download/1.2.1/rips-cli.phar -O ./rips-cli
chmod 755 ./rips-cli

./rips-cli rips:scan:start -a "${RIPS_APPLICATION_ID}" -p ./"${REPO}".zip
