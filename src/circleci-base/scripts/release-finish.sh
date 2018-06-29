#!/usr/bin/env bash

new_version=$1
commit_message=":robot: ${2:-Automated promotion}"

if ! git flow release finish $new_version --showcommands -p -m $commit_message
then
  # Force merge conflicts to be --ours
  grep -lr '<<<<<<<' . | xargs git checkout --ours
  git add .
  git flow release finish $new_version --showcommands -p -m $commit_message
fi
