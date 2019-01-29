#!/usr/bin/env bash
set -euo pipefail

# Description: Prepare NRO release branch
#
# Triggered in CI after successful develop branch build/deploy
# Starts or continues a new branch release/vx.x.x
# Merges changes from develop
# Deletes previous release branch from origin
# Pushes changes to origin
#
old_release=$(git-current-tag.sh)
new_release=$(git-new-version.sh)

# Check for numeric value of new release version
# Permits optional leading 'v' character
[[ ${new_release#v} =~ ^[0-9] ]] || {
  echo "ERROR: release is not numeric: '${new_release#v}'"
  exit 1
}

echo "-- 0.1   The old release is $old_release"
echo "-- 0.2   The new release is $new_release"

merged=false

mkdir -p /tmp/workspace

echo "-- 1.0   Before the first if"
if release-start.sh "$new_release"
then
  echo "-- 1.1   New release branch created: release/$new_release"
  merged=true
else
  echo "-- 1.1   Release branch release/$new_release already exists"
  # Release branch already exists
  git checkout "release/$new_release"

  # If there are any changes from develop
  # Merge changes from develop to release
  git merge -Xtheirs --no-edit --log -m ":robot: release/$new_release Merge develop" develop | tee /tmp/workspace/merge.log

  grep -q "Already up-to-date." /tmp/workspace/merge.log || {
    echo "-- 1.2   We merged changes from develop into release/$new_release"
    merged=true;
  }
fi

# Perform NRO develop to release manipulations
echo
echo "-- 2.0   Performing automated release modifications ..."
pin-composer-versions.sh

# If there are any local changes
if ! git diff --exit-code
then
  echo "-- 2.1   Staging modifications"
  # Stage changes
  git add .

  if [[ "$merged" = "true" ]]
  then
    echo "-- 2.1.1 Since we've merged changes from develop, let's amend that commit"
    git commit --amend --no-edit
  else
    echo "-- 2.1.2 Create new commit with automated modifications"
    git commit -m ":robot: release/$new_release Automated modifications"
    merged=true
  fi
fi

if [[ "$merged" = "false" ]]
then
  # No local changes
  repo=$(git remote get-url origin | cut -d'/' -f 2 | cut -d'.' -f1)
  echo "-- 3.1   No changes to merge. Triggering $repo@release/$new_release via API"
  trigger-build-api.sh "$repo" "release/$new_release"
else
  echo "-- 3.2   Local changes have been merged, pushing changes to remote"

  echo "-- 3.2.1 Remove all the build trigger notifications from the latest commit message"
  # Remove all the build trigger notifications from the latest commit message
  message=$(git show --format=%B | grep -v ":robot: Build trigger")
  git commit --amend -m "$message"

  echo "---3.2.2 Push the new release branch release/$new_release"
  # Push the new release branch
  git push -u origin "release/$new_release"

  echo "---3.2.3 Check if old release branch still exists"
  gitlsremote=$(git ls-remote | grep release | grep -v "release/$new_release")
  if [[ $gitlsremote =~ release/$old_release ]]
  then
    # Delete the old release branch
    echo "---3.2.4 Delete stale release branch: release/$old_release"
    git push origin --delete "release/$old_release"
  fi

fi
