#!/usr/bin/env bats

load test_helper

@test "Task 3: NA_VERSION_TO_SHOW defined in script" {
  run grep -q 'NA_VERSION_TO_SHOW=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 3: Script uses parse_options for argument parsing" {
  run grep -q 'parse_options' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 3: --help prints usage and exits 0" {
  run "$SCRIPT_PATH" --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "usage\|always-nvim\|help"
}

@test "Task 3: -h prints usage and exits 0" {
  run "$SCRIPT_PATH" -h
  # parse_options might exit 1 if not explicitly handled or if considered an error by some, but standard is 0.
  # The original test allowed 1 if needed but preferred 0.
  # Let's check status. If it fails, we'll see.
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "usage\|always-nvim\|help"
}

@test "Task 3: --version prints version and exits 0" {
  run "$SCRIPT_PATH" --version
  [ "$status" -eq 0 ]
  echo "$output" | grep -E '[0-9]+\.[0-9]+'
}

@test "Task 3: -v prints version and exits 0" {
  run "$SCRIPT_PATH" -v
  [ "$status" -eq 0 ]
  echo "$output" | grep -E '[0-9]+\.[0-9]+'
}
