#!/usr/bin/env bash
set -euo pipefail

for file in /tmp/workspace/src/post_deploy_scripts/*.sh; do
    echo ""
    echo "Running the local script : $(basename "$file")"
    echo ""
    $file
done

