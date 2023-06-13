#!/usr/bin/env bash
set -euo pipefail

workspace=/tmp/workspace/src

[ -d "$workspace/tasks/post-deploy" ] || {
  echo "No post-deploy task folder found in $workspace"
  ls -al "$workspace"
  exit 0
}

for file in "$workspace"/tasks/post-deploy/*; do
  echo ""
  filename=$(basename "$file")
  echo "Running the script: ${filename}"
  echo ""

  if [[ $filename == *"-pods-"* ]]; then
    echo "Running script in all php pods"
    echo ""
    run_bash_script_in_all_php_pods.sh "$file"
  elif [[ $filename == *"-openresty-"* ]]; then
    echo "Running script in all openresty pods"
    echo ""
    run_bash_script_in_all_openresty_pods.sh "$file"
  else
    run_bash_script_in_php_pod.sh "$file"
  fi
done
