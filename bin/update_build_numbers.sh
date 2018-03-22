#!/usr/bin/env bash
set -exo pipefail

# Description:  Updates readme & dockerfiles with current build information.
#               Pushes new commit with updated data.

# If the build url isn't set, we're building locally and don't want to update
if [[ -z "${CIRCLE_BUILD_URL}" ]]
then
  echo "Local build, skipping repository update..."
  exit 0
fi

# Circle doesn't set the branch variable for tagged builds
if [[ "${CIRCLE_TAG}" ]] && [[ -z "${CIRCLE_BRANCH}" ]]
then
  # So find the branch associated with this tag
  git remote update
  # Find which remote branch contains the current commit
  CIRCLE_BRANCH=$(git branch -r --contains ${CIRCLE_SHA1} | grep -v 'HEAD' | awk '{split($1,a,"/"); print a[2]}')
  # Checkout that branch / tag
  git checkout ${CIRCLE_BRANCH}
  # Sanity check via SHA
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

# -----------------------------------------------------------------------------
# SET CURRENT_DIR FROM REAL PATH
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  # if $source was a relative symlink, we need to resolve it relative to the
  # path where the symlink file was located
  [[ $source != /* ]] && source="$dir/$source"
done
CURRENT_DIR="$( cd -P "$( dirname "$source" )" && pwd )"
# -----------------------------------------------------------------------------

# Build without arguments to update Dockerfile from template
${CURRENT_DIR}/build.sh

# Configure git user
git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"
git config push.default simple
# Add changes
git add .
# Get previous commit message and append a message, skipping CI
OLD_MSG=$(git log --format=%B -n1)
git commit -m ":robot: $OLD_MSG" -m "- update build numbers [skip ci]"
# Push the updated Dockerfile and README to the repo
git push --force-with-lease --set-upstream origin ${CIRCLE_BRANCH}
