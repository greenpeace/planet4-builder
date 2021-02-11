#!/usr/bin/env bash
set -euo pipefail

FILE="/tmp/workspace/composer.json"

[ -e "$FILE" ] || {
  echo >&2 "File not found: $FILE"
  exit 1
}

version=$(jq -r .version <$FILE)

echo "$version"
