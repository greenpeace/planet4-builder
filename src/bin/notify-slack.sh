#!/usr/bin/env bash
# shellcheck disable=SC2016
set -u

MSG_USERNAME=${MSG_USERNAME:-CircleCI}
MSG_TYPE=${MSG_TYPE:-Notification}
MSG_ICON=${MSG_ICON:-'https://dmmj3mmt94rvw.cloudfront.net/favicon-undefined.ico'}
MSG_TITLE=${MSG_TITLE:-'circleci.com/gh/greenpeace'}
MSG_LINK=${MSG_LINK:-'https://circleci.com/gh/greenpeace'}
MSG_TEXT=${MSG_TEXT:-'https://circleci.com/gh/greenpeace'}
MSG_COLOUR=${MSG_COLOUR:-'f5f5f5'}
MSG_IMAGE=${MSG_IMAGE:-}

# shellcheck disable=SC2016
json=$(jq -n \
  --arg MSG_USERNAME "$MSG_USERNAME" \
  --arg MSG_TYPE "$MSG_TYPE" \
  --arg MSG_ICON "$MSG_ICON" \
  --arg MSG_TITLE "$MSG_TITLE" \
  --arg MSG_LINK "$MSG_LINK" \
  --arg MSG_TEXT "$MSG_TEXT" \
  --arg MSG_COLOUR "$MSG_COLOUR" \
  --arg MSG_IMAGE "$MSG_IMAGE" \
  '{
  "username": $MSG_USERNAME,
  "text": $MSG_TYPE,
  "icon_url": $MSG_ICON,
  "attachments": [
    {
      "title": $MSG_TITLE,
      "title_link": $MSG_LINK,
      "text": $MSG_TEXT,
      "color": $MSG_COLOUR,
      "image_url": $MSG_IMAGE,
    }
  ]
}')

curl -X POST -H 'Content-Type: application/json' \
  --data "$json" \
  "${SLACK_INFRA_WEBHOOK}"
