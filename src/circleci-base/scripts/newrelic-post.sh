#!/usr/bin/env bash
set -eu

endpoint=$1
payload=$2

curl -X POST "$endpoint" \
  -H "X-Api-Key:${NEWRELIC_REST_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$payload"
