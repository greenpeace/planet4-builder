#!/usr/bin/env bash
set -e

# Configure git user
git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"
git config push.default simple

git flow init -d

git flow release start --showcommands $1
