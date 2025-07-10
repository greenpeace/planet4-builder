#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh -h" {
  expected="Usage: $(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh"
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" -h
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -Eq "$expected"
}
