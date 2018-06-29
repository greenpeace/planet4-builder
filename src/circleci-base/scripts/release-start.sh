#!/usr/bin/env bash
set -e

git flow init -d

git flow release start $1
