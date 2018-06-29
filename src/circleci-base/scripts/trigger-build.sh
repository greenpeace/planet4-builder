#!/usr/bin/env bash
set -u

repo=$1
branch=${2:-develop}

export TYPE="Trigger: $repo:$branch"

# Checkout dependent repository
git clone $repo && \
  cd planet4-builder && \
  git checkout $branch && \
  git commit --allow-empty -m ":robot: Build trigger from ${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} Build #${CIRCLE_BUILD_NUM}" -m "${CIRCLE_BUILD_URL}" && \
  git push --force-with-lease --set-upstream origin $branch && \
  ${HOME}/scripts/notify-job-success.sh && \
  exit 0

# No bueno
${HOME}/scripts/notify-job-failure.sh
exit 1
