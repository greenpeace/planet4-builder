#!/usr/bin/env bash
set -xo pipefail

new_version=$1
commit_message=":robot: ${2:-Automated promotion}"
diff_log=$(git log --oneline "$(git-current-tag.sh)..." | grep -v ":robot:")

export GIT_MERGE_AUTOEDIT=no

git flow release finish $new_version --showcommands -p -m "$commit_message" -m "${diff_log//[\'\"\`]}" 2>&1 | tee ${TMPDIR:-/tmp}/gitflow.log

status=$?

if [ $status -ne 0 ]
then

  # We have the technology
  if grep -q "Fatal: There were merge conflicts" ${TMPDIR:-/tmp}/gitflow.log
  then
    # Force merge conflicts to be --ours
    grep -lr '<<<<<<<' . | xargs git checkout --ours
    git add .
    old_message=$(git log --format=%B -n1)
    git commit --amend -m "$old_message" -m ":robot: Resolve merge conflicts --ours"
    git flow release finish $new_version --showcommands -p -m $commit_message
    exit $?
  fi

  # Can't fix this, return previous error
  exit $status
fi

unset GIT_MERGE_AUTOEDIT
exit 0
