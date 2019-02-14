#!/usr/bin/env bash
set -euo pipefail


echo "Check the post deploy scripts and run them as well"
echo "Check if merged source is persisted from previous job"
if [ -d /tmp/workspace/src/tasks/post-deploy ]; then

    cp -f /tmp/workspace/src/post_deploy_scripts/* /tmp/workspace/src/tasks/post-deploy

    for file in /tmp/workspace/src/tasks/post-deploy/*; do
        echo ""
        echo "Running the script : $(basename "$file")"
        echo ""
        HELM_NAMESPACE=${HELM_NAMESPACE} \
          HELM_RELEASE=${HELM_RELEASE} \
          ./run_bash_script_in_php_pod.sh "$file"
    done
fi
