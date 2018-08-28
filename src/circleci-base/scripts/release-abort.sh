#!/usr/bin/env bash
set -eux

git flow release

release=${1:-$(git flow release | head | tr -s ' ' | cut -d' ' -f2)}

git reset --hard

git checkout ${CIRCLE_SHA1:-develop}

git flow release delete -f $release
