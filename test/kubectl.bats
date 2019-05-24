#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "${BATS_SOURCE//.bats/}") version --client --short" {
  expected="^Client Version: v$VERSION_REGEX"
  run run_docker_binary "$BATS_IMAGE" "$(basename "${BATS_SOURCE//.bats/}")" "version --client --short"
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -Eq "$expected"
}
