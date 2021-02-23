#!/usr/bin/env bash
# shellcheck disable=SC2016
set -eu

repo=$1
user=greenpeace
branch=${2:-main}

json=$(jq -n \
  --arg VAL "$branch" \
  '{
	"branch": $VAL
}')

echo "Build: ${user}/${repo}@${branch}"

curl \
  --header "Content-Type: application/json" \
  -d "$json" \
  -u "${CIRCLE_TOKEN}:" \
  -X POST \
  "https://circleci.com/api/v1.1/project/github/${user}/${repo}/build"
