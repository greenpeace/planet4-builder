#!/usr/bin/env bash
set -u

repo=$1
branch=${2:-develop}

export TYPE="Trigger: $repo:$branch"

dir=$(echo $repo | tr -dc 'a-zA-Z0-9' | head -n 1)

rm -fr $dir
mkdir $dir

# Checkout dependent repository and trigger CI with empty commit.
git clone $repo $dir && \
  cd $dir && \
  git config user.email "circleci-bot@greenpeace.org" && \
  git config user.name "CircleCI Bot" && \
  git config push.default simple && \
  git checkout $branch && \
  git commit --allow-empty -m ":robot: Build trigger from ${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} Build #${CIRCLE_BUILD_NUM}" -m "${CIRCLE_BUILD_URL}" && \
  git push --force-with-lease --set-upstream origin $branch && \
  notify-job-success.sh && \
  exit 0

# No bueno
notify-job-failure.sh
exit 1
