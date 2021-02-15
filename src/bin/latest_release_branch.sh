#!/usr/bin/env bash
set -euo pipefail

repo=${1:-greenpeace/planet4-master-theme}

curl -s "https://api.github.com/repos/${repo}/branches" | jq -r 'limit(1; sort_by(.name) | reverse | .[].name | select(startswith("release")))'
