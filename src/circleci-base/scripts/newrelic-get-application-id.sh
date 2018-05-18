#!/usr/bin/env bash
set -eu

# Return NewRelic application ID from Name

# Set application name from first parameter,
# fallback to NEWRELIC_APPNAME or error if unset
appname=${1:-${NEWRELIC_APPNAME}}

./newrelic-get.sh \
  "https://api.newrelic.com/v2/applications.json" \
  jq "[.applications[] | select(.name == \"${appname}\")][] | .id"
