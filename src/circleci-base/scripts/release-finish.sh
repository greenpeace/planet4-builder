#!/usr/bin/env bash
set -x

new_version=$1
commit_message=":robot: ${2:-Automated promotion}"

export GIT_MERGE_AUTOEDIT=no

git flow release finish $new_version --showcommands -p -m $commit_message 2>&1 | tee ${TMPDIR:-/tmp}/gitflow.log

if grep "Fatal: There were merge conflicts" ${TMPDIR:-/tmp}/gitflow.log
then
  # Force merge conflicts to be --ours
  grep -lr '<<<<<<<' . | xargs git checkout --ours
  git add .
  git commit -m ":robot: Resolve merge conflicts --ours"
  git flow release finish $new_version --showcommands -p -m $commit_message
fi

unset GIT_MERGE_AUTOEDIT
