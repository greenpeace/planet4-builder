#!/usr/bin/env bash
set -ex

# If the build url isn't set, we're building locally so
if [[ -z "${CIRCLE_BUILD_URL}" ]]
then
  # Don't attempt to update the repository
  echo "Local build, skipping repository update..."
  exit 0
fi

if [[ -z "${CIRCLE_BRANCH}" ]] && [[ "${CIRCLE_TAG}" ]]
then
  # Find the branch associated with this commit
  # Why is this so hard, CircleCI?
  git remote update
  # Find which remote branch contains the current commit
  CIRCLE_BRANCH=$(git branch -r --contains ${CIRCLE_SHA1} | grep -v 'HEAD' | awk '{split($1,a,"/"); print a[2]}')

  if [[ -z "$CIRCLE_BRANCH" ]]
  then
      >&2 echo "Could not reliably determine branch"
      >&2 echo "Forcing master (since they should be the only branches tagged)"
      CIRCLE_BRANCH=master
  fi

  # Checkout that branch / tag
  git checkout ${CIRCLE_BRANCH}
  if [[ "$(git rev-parse HEAD)" != "${CIRCLE_SHA1}" ]]
  then
    >&2 echo "Found the wrong commit!"
    >&2 echo "Wanted: ${CIRCLE_SHA1}"
    >&2 echo "Got:    $(git rev-parse HEAD)"
    >&2 echo "Not updating build details in repository, continuing ..."
    exit 0
  fi
fi
echo "${CIRCLE_BRANCH}" > /tmp/workspace/var/circle-branch-name
export CIRCLE_BRANCH

# Configure git user
git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"
git config push.default simple

# Build without arguments to update Dockerfile from template
./bin/build.sh

# Add changes
git add .

# Exit early if no changes to write
git diff-index --quiet HEAD -- && exit 0

# Get previous commit message and append a message, skipping CI
OLD_MSG=$(git log --format=%B -n1)
git commit -m ":robot: Update build numbers ${CIRCLE_TAG:-${CIRCLE_BRANCH}}" -m " - $OLD_MSG [skip ci]"
# Push updated files to the repo
git push --force-with-lease --set-upstream origin ${CIRCLE_BRANCH}
