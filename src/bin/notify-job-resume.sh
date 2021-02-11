#!/usr/bin/env bash
set -eu

MSG_TYPE="RESUME: ${TYPE:-Job} - ${CIRCLE_PROJECT_REPONAME} - ${CIRCLE_JOB}" \
  MSG_TITLE="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} @ ${CIRCLE_BRANCH:-${CIRCLE_TAG}}" \
  MSG_LINK="https://circleci.com/workflow-run/${CIRCLE_WORKFLOW_WORKSPACE_ID}" \
  MSG_TEXT="Build: #${CIRCLE_BUILD_NUM} ${EXTRA_TEXT:-}" \
  MSG_COLOUR="lightblue" \
  "${HOME}/scripts/notify-slack.sh"
