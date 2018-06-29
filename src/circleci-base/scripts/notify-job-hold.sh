#!/usr/bin/env bash
set -eu

MSG_TYPE="HOLD: ${TYPE:-Job} - ${CIRCLE_PROJECT_REPONAME} - ${CIRCLE_JOB}" \
MSG_TITLE="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} @ ${CIRCLE_BRANCH:-${CIRCLE_TAG}}" \
MSG_LINK="https://circleci.com/workflow-run/${CIRCLE_WORKFLOW_WORKSPACE_ID}" \
MSG_TEXT="Build: #${CIRCLE_BUILD_NUM} Diff: ${CIRCLE_COMPARE_URL} ${EXTRA_TEXT:-}" \
MSG_COLOUR="#ab7fd1" \
"${HOME}/scripts/notify-rocketchat.sh"
