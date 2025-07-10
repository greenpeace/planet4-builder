#!/usr/bin/env bash
set -euo pipefail

ID="$1"
echo "ID: ${ID}"

url="https://circleci.com/api/v2/workflow/${ID}/job"

# Get workflow details
workflow=$(curl -s -u "${CIRCLE_TOKEN}": -X GET --header "Content-Type: application/json" "$url")

# Get approval job id
job_id=$(echo "$workflow" | jq -r '.items[] | select(.name=="hold-production") | .approval_request_id ')
echo "JOB ID: ${job_id}"

# Approve
curl \
  --header "Content-Type: application/json" \
  -u "${CIRCLE_TOKEN}:" \
  -X POST \
  "https://circleci.com/api/v2/workflow/${ID}/approve/${job_id}"
