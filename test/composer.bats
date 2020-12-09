#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1) --version" {
  expected="Composer version\\s$VERSION_REGEX"
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1)" --no-ansi --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$expected"
}
