#!/usr/bin/env bash
set -euo pipefail

echo "${DOCKER_PASS_64}" | base64 --decode | docker login --username "$(echo "${DOCKER_USER_64}" | base64 --decode)" --password-stdin
