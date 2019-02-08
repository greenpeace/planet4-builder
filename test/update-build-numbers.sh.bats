#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "${BATS_SOURCE//.bats/}") -h" {
  expected="Usage: $(basename "${BATS_SOURCE//.bats/}")"
  run run_docker_binary "$BATS_IMAGE" "$(basename "${BATS_SOURCE//.bats/}")" -h
  [ "$status" -eq 0 ]
  printf '%s' "$output" | grep -Eq "$expected"
}
