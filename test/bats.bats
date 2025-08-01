#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1) --version" {
  run run_docker_binary "$BATS_IMAGE" bats --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "Bats $VERSION_REGEX"
}
