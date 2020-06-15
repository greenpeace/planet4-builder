#!/usr/bin/env bash
set -u

repo=$1
branch=${2:-develop}

dir=$(echo "$repo" | tr -dc 'a-zA-Z0-9' | head -n 1)

rm -fr "$dir"
mkdir "$dir"

echo "Triggering $repo"

GIT_COMMIT_MESSAGE=$(git --git-dir=/tmp/workspace/.git log --format=%B -n 1 "$CIRCLE_SHA1")
if [[ $GIT_COMMIT_MESSAGE == *"[HOLD]"* ]]; then
  GIT_PREFIX=" [HOLD]"
else
  GIT_PREFIX=""
fi

# Checkout dependent repository and trigger CI with empty commit.
git clone "$repo" "$dir"
cd "$dir" || exit 1
git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"
git config push.default simple
git checkout "$branch"
if [ "$branch" == "develop" ]; then
  git commit --allow-empty -m ":robot:${GIT_PREFIX} Trigger build #${CIRCLE_BUILD_NUM}" -m "${CIRCLE_BUILD_URL}"
  git push origin "$branch"
else
  current_version=$(git describe --abbrev=0 --tags)
  new_version=$(increment-version.sh "$current_version")
  git tag -a "$new_version" -m "$new_version"
  git push origin --tags
fi
