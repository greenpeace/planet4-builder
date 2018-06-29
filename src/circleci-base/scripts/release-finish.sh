#!/usr/bin/env bash
set -e

git flow release finish $1 --showcommands -p -m ":robot: ${2:-Automated promotion}"
