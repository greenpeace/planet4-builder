#!/usr/bin/env bash
# shellcheck disable=SC2016
set -eu

repo=$1
user=greenpeace
tag=$2

json=$(jq -n \
  --arg VAL "$tag" \
'{
	"tag": $VAL
}')

echo "Build: ${user}/${repo}@${tag}"

curl \
  --header "Content-Type: application/json" \
  -d "$json" \
  -u "${CIRCLE_TOKEN}:" \
  -X POST \
  "https://circleci.com/api/v1.1/project/github/${user}/${repo}/build"
