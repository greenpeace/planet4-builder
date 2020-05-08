#!/usr/bin/env bash
set -o pipefail

# Configure git user
git config user.email "circleci-bot@greenpeace.org"
git config user.name ":robot: CI Bot"
git config push.default simple

# Merge develop branch to release
git checkout -t origin/release
git merge -Xtheirs --no-ff --no-edit develop
git push origin release
