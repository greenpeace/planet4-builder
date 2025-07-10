#!/usr/bin/env bash
set -o pipefail

if [[ -z "$1" ]]; then
  current_version=$(git-current-tag.sh)
  new_version=$(increment-version.sh "$current_version")
else
  new_version=$1
fi

# Configure git user
git config user.email "${GIT_USER_EMAIL}"
git config user.name "CircleCI Bot"
git config push.default simple

# Store any local changes
git stash

# Initialised git flow in this repository
git flow init -d || exit 1

# Apply any stashed changes
git stash pop

# Begin a new release
git flow release start "$new_version" || exit 1

# Merge origin/master into this release, preferring our changes
# git merge -Xours origin/master --commit 2>&1 | tee "${TMPDIR:-/tmp}/merge-master.log.0"
#
# status=$?
# count=0
# limit=3
#
# # If the merge wasn't clean, attempt to resolve
# while [ $status -ne 0 ]
# do
#   # File is deleted in HEAD but exists in master
#   deleted=$(cat "${TMPDIR:-/tmp}/merge-master.log.$count" | grep "CONFLICT (modify/delete)" | grep "deleted in HEAD" | cut -d' ' -f3)
#
#   if [[ ${#deleted} -gt 0 ]]
#   then
#     for file in $deleted
#     do
#       git rm $file
#     done
#
#     git commit -m ":robot: Merge conflict resolve: deleted files"
#   fi
#
#   count=$((count+1))
#   [ $count -gt $limit ] && >&2 echo "ERROR: too many attempts" && exit 1
#
#   git merge -Xours origin/master --commit 2>&1 | tee "${TMPDIR:-/tmp}/merge-master.log.$count"
#   status=$?
#
# done
