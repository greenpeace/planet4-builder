#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "${BATS_SOURCE//.bats/}") --version" {
  expected="Composer version\\s$VERSION_REGEX"
  run run_docker_binary "$BATS_IMAGE" "$(basename "${BATS_SOURCE//.bats/}")" --no-ansi --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$expected"
}
