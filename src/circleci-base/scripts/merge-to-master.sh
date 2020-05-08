#!/usr/bin/env bash
set -o pipefail

# Configure git user
git config user.email "circleci-bot@greenpeace.org"
git config user.name ":robot: CI Bot"
git config push.default simple

# Merge release branch to master
git checkout -t origin/release
git checkout -t origin/master
git merge -Xtheirs --no-ff --no-edit release
git push origin master
