#!/usr/bin/env bash
set -eo pipefail

# Store current build number for future jobs
mkdir -p /tmp/workspace/var
echo "${CIRCLE_BUILD_NUM}" > /tmp/workspace/var/circle-build-num

# Show bash version
bash --version

# Show kernel information
uname -a

# Not all distributions will have lsb_release
if [[ $(type -P "lsb_release") ]]
then
  lsb_release -a
fi

# bats version
bats -v

# ack version
ack --version
