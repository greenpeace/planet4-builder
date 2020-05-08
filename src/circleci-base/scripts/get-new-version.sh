#!/usr/bin/env bash
set -euo pipefail

FILE="/tmp/workspace/src/composer.json"

[ -e "$FILE" ] || {
  >&2 echo "File not found: $FILE"
  exit 1
}

version=$(jq -r .version < composer.json)

echo "$version"