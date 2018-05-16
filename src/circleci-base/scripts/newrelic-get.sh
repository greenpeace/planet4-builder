#!/usr/bin/env bash
set -eu

endpoint=$1
payload=$2

echo "curl: $endpoint"

curl -s -X GET "${endpoint}" \
     -H "X-Api-Key:${NEWRELIC_REST_API_KEY}" \
     "${payload}"
