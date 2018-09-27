#!/usr/bin/env bash

if [ -z "$(git tag)" ]
then
  exit 0
fi

# git describe --tags "$(git rev-list --tags --max-count=1)"

repo="https://github.com/$(git remote get-url origin | cut -d: -f2 | cut -d'.' -f1)"

./git-latest-remote-tag.awk $repo
