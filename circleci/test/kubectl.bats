#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1) version --client" {
  expected="^Client Version: v$VERSION_REGEX"
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1)" "version --client"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -Eq "$expected"
}
