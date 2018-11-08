#!/usr/bin/env bash
set -euo pipefail

users="$(base64 -d <<<"$1")"

numusers="$(jq -n "$users | .users | length" )"

echo "Updating $numusers users ..."

i=0
while (( i < numusers ))
do
  user=$(jq -Mn "$users | .users[$i]")
  i=$((i+1))

  display_name="$(jq -rn "$user | .display_name")"
  first_name="$(jq -rn "$user | .first_name")"
  last_name="$(jq -rn "$user | .last_name")"
  role="$(jq -rn "$user | .role")"
  user_email="$(jq -rn "$user | .user_email")"
  user_login="$(jq -rn "$user | .user_login")"

  if wp user get "$user_email" >/dev/null
  then
    echo "[$i/$numusers] > Update $role: $user_login"
    wp user update \
      "$user_login" \
      --display_name="$display_name" \
      --first_name="$first_name" \
      --last_name="$last_name" \
      --quiet \
      --role="$role" \
      --skip-email \
      --user_email="$user_email"
  else
    echo "[$i/$numusers] > Create $role: $user_login"
    wp user create \
      "$user_login" \
      "$user_email" \
      --display_name="$display_name" \
      --first_name="$first_name" \
      --last_name="$last_name" \
      --porcelain \
      --quiet \
      --role="$role"
  fi

done
