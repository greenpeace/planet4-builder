#!/usr/bin/env bash
set -xo pipefail

new_version=$1
commit_message=":robot: ${2:-Automated promotion}"
# diff_log=$(git log --oneline "$(git-current-tag.sh)..." | grep -v ":robot:")

# Ensure master branch is up to date with origin
git checkout master
git reset --hard origin/master
git merge --no-edit --no-ff --log -m "$commit_message" release/${new_version}

status=$?
count=0
limit=3

while [ $status -ne 0 ]
do
  count=$((count+1))
  [ $count -gt $limit ] && exit 1

  # We have the technology
  if grep -q "^Fatal\: " ${TMPDIR:-/tmp}/gitflow.log
  then
    # Force merge conflicts to be --ours
    grep -lr '<<<<<<<' . | xargs git checkout --ours
    git add .
    old_message="$(git log --format=%B -n1)"
    git commit --amend -m "$old_message" -m ":robot: Resolve merge conflicts --ours" \
      && git flow release finish $new_version --showcommands -b -p -m "$commit_message" | tee ${TMPDIR:-/tmp}/gitflow.log
    status=$?
  fi
done

exit 0
