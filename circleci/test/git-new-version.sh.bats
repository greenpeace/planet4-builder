#!/usr/bin/env bats
set -eu

load .env

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh [ci tag v1.2.3-test]" {
  v=v1.2.3-test
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "'[ci tag $v]'"
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$v"
  >&2 printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh [ci tag 1.2.3]" {
  v=1.2.3
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "'[ci tag $v]'"
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$v"
  printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh Multiple semver strings: [ci tag v2.3.4-test]" {
  v=v2.3.4-test
  string=$(cat <<EOF
Test 0.1.2

Thing

[ci tag $v]
EOF)
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" $string
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$v"
  printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh Release blah [ci tag 0.20.30a-build42]" {
  v=0.20.30a-build42
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "'[ci tag $v]'"
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$v"
  printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh [ci release 1.2.3]" {
  v=1.2.3
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "[ci tag $v]"
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$v"
  >&2 printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh [ci promote 1.2.3]" {
  v=1.2.3
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "[ci promote $v]"
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$v"
  >&2 printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh [ci error 1.2.3]" {
  ci="ci error 1.2.3"
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "[$ci]"
  [ $status -eq 0 ]
  v=v0.0.1
  printf '%s' "$output" | grep -Eq "$v"
  >&2 printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh [ci error blahblah]" {
  ci="ci error blahblah"
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "[$ci]"
  [ $status -eq 0 ]
  v=v0.0.1
  printf '%s' "$output" | grep -Eq "$v"
  >&2 printf '%s' "$output"
}

@test "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh [ci tag blahblah]" {
  ci="ci tag blahblah"
  run run_docker_binary "$BATS_IMAGE" "$(basename "$BATS_TEST_FILENAME" | cut -d. -f1).sh" "[$ci]"
  v=v0.0.1
  printf '%s' "$output" | grep -Eq "$v"
  >&2 printf '%s' "$output"
}
