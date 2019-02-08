#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "${BATS_SOURCE//.bats/}") --version" {
  expected="Google Cloud SDK\\s$VERSION_REGEX"
  run run_docker_binary "$BATS_IMAGE" "$(basename "${BATS_SOURCE//.bats/}")" --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "Google Cloud SDK\\s$VERSION_REGEX"
  printf '%s' "$output" | grep -Eq "kubectl\\s$VERSION_REGEX"
  printf '%s' "$output" | grep -Eq "cloud_sql_proxy"
}
