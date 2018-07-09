#!/usr/bin/env bash

if [ -z "$(git tag)" ]
then
  exit 0
fi

git describe --tags "$(git rev-list --tags --max-count=1)"
