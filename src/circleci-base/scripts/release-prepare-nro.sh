#!/usr/bin/env bash
set -exuo pipefail

# Description: Prepare NRO release branch
#
# Triggered in CI after successful develop branch build/deploy
# Starts or continues a new branch release/vx.x.x
# Merges changes from develop
# Deletes previous release branch from origin
# Pushes changes to origin
#

old_release=${1:-$(git-current-tag.sh)}
new_release=${2:-$(increment-version.sh $old_release)}

merged=false

mkdir -p /tmp/workspace

if release-start.sh $new_release
then
  merged=true
else
  # Release branch already exists
  git checkout release/$new_release

  # If there are any changes from develop
  # Merge changes from develop to release
  git merge -Xtheirs --no-edit --log -m ":robot: release/$new_release Merge develop" develop | tee /tmp/workspace/merge.log
  grep -q "Already up-to-date." /tmp/workspace/merge.log  || merged=true
fi

# Perform NRO develop to release manipulations
pin-composer-versions.sh

# If there are any local changes
if ! git diff --exit-code
then

  git add .

  # We have local changes
  if [[ "$merged" = "true" ]]
  then
    echo "Since we've merged changes from develop, let's amend that commit"
    git commit --amend --no-edit
  else
    echo "New commit with automated modifications"
    git commit -m ":robot: release/$new_release Automated modifications "
  fi
else
  # No local changes
  if [[ "$merged" = "true" ]]
  then
    echo "Nothing to do: no new changes and have already merged develop -> release in this job"
  else
    echo "Creating empty commit as new build trigger ..."
    git commit --allow-empty -m ":robot: release/$new_release Build trigger"
  fi
fi

message=$(git show --format=%B | grep -v ":robot: Build trigger")

# Remove all the build trigger notifications from the latest commit message
git commit --allow-empty --amend -m "$message"

# Create the new release branch
git push -u origin release/$new_release

# Delete the old release branch
git push origin --delete release/$old_release || exit 0
