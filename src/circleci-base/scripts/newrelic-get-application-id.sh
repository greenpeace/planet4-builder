#!/usr/bin/env bash
set -eu

# Return NewRelic application ID from Name

# Set application name from first parameter,
# fallback to NEWRELIC_APPNAME or error if unset
# Replace spaces with + characters
appname=$(tr ' ' '+' <<< ${1:-${NEWRELIC_APPNAME}})

appId=$(curl -s -X GET "https://api.newrelic.com/v2/applications.json" \
     -H "X-Api-Key:${NEWRELIC_REST_API_KEY}" \
     -G -d "filter[name]=${appname}" | jq ".applications[].id")

echo "$appId"
