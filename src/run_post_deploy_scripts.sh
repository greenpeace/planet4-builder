#!/usr/bin/env bash
set -euo pipefail

workspace=/tmp/workspace/src

[ -d "$workspace/tasks/post-deploy" ] || {
  echo "No post-deploy task folder found in $workspace"
  ls -al "$workspace"
  exit 0
}

cp -f "$workspace/post_deploy_scripts/*" "$workspace/tasks/post-deploy"
rm -rf "$workspace/post_deploy_scripts"

for file in "$workspace"/tasks/post-deploy/*
do
    echo ""
    echo "Running the script : $(basename "$file")"
    echo ""
    ./run_bash_script_in_php_pod.sh "$file"
done
