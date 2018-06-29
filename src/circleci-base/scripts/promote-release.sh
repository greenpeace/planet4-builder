#!/usr/bin/env bash
set -e

current_version=$(git describe --tags "$(git rev-list --tags --max-count=1)")
new_version=$(increment-version.sh $current_version)

echo "Found existing tag: $current_version"
echo "Promoting branch ${CIRCLE_BRANCH} to release/${new_version}"
