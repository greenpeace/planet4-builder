#!/usr/bin/env bash
set -euo pipefail

repo=${1:-greenpeace/planet4-master-theme}

all_branches=$(curl -s "https://api.github.com/repos/${repo}/branches")

latest_release=$(echo "$all_branches" | jq 'limit(1; sort_by(.name) | reverse | .[].name | select(startswith( "release")))')

eval printf "%s" "$latest_release"

