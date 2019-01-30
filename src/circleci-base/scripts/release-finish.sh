#!/usr/bin/env bash
set -xo pipefail

if [[ -z "$1" ]]
then
  new_version=${CIRCLE_BRANCH#release/}
else
  new_version=$1
fi

commit_message=":robot: ${2:-Automated promotion}"

git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"

# Ensure master branch is up to date with origin
git checkout master
git reset --hard origin/master

# Merge release into master, with strategy Xtheirs
git merge -Xtheirs --no-edit --no-ff --log -m "$commit_message" "${CIRCLE_BRANCH}" | tee "${TMPDIR:-/tmp}/git.log"

status=$?
count=0
limit=3

while [ $status -ne 0 ]
do
  count=$((count+1))
  [ $count -gt $limit ] && exit 1

  # We have the technology
  if grep -q "^Fatal\\: " "${TMPDIR:-/tmp}/git.log"
  then
    # Force merge conflicts to be --ours
    grep -lr '<<<<<<<' . | xargs git checkout --ours
    git add .
    old_message="$(git log --format=%B -n1)"
    git commit --amend -m "$old_message" -m ":robot: Resolve merge conflicts --ours"
    status=$?
  fi
done

git tag -m "$commit_message" -a "$new_version"

git push origin master

git push origin --tags

# Tidy up old releases
for release in $(git ls-remote --heads origin | grep release/ | cut -f2)
do
  git push origin --delete "${release}"
done

exit 0
