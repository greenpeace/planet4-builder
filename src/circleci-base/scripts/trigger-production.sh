#!/usr/bin/env bash
set -eu

repo=$1
user=greenpeace
tag=$2

json=$(jq -n \
  --arg VAL "$tag" \
  --arg RELEASE_STAGE "production" \
  '{
    "tag": $VAL,
    "parameters": {
      "release_stage": $RELEASE_STAGE
    }
}')

echo "Build: ${user}/${repo}@${tag}"

curl \
  --header "Content-Type: application/json" \
  -d "$json" \
  -u "${CIRCLE_TOKEN}:" \
  -X POST \
  "https://circleci.com/api/v2/project/github/${user}/${repo}/pipeline"
