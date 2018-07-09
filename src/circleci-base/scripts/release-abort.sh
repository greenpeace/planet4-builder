#!/usr/bin/env bash
set -eu

release=${1:-$(git flow release | cut -d" " -f2)}

git reset --hard

git checkout $CIRCLE_SHA1

git flow release delete $release
