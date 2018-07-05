#!/usr/bin/env bash
set -o pipefail

if [[ -z "$1" ]]
then
  current_version=$(git-current-tag.sh)
  new_version=$(increment-version.sh $current_version)
else
  new_version=$1
fi

# Configure git user
git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"
git config push.default simple

git flow init -d

git flow release start $new_version

git merge -Xours origin/master --commit 2>&1 | tee /tmp/merge-master.log.0

status=$?
count=0
limit=3

while [ $status -ne 0 ]
do
  # File is deleted in HEAD but exists in master
  deleted=$(cat /tmp/merge-master.log.$count | grep "CONFLICT (modify/delete)" | grep "deleted in HEAD" | cut -d' ' -f3)

  if [[ ${#deleted} -gt 0 ]]
  then
    for file in $deleted
    do
      git rm $file
    done

    git commit -m ":robot: Merge conflict resolve: deleted files"
  fi

  count=$((count+1))
  [ $count -gt $limit ] && >&2 echo "ERROR: too many attempts" && exit 1

  git merge -Xours origin/master --commit 2>&1 | tee /tmp/merge-master.log.$count
  status=$?

done
