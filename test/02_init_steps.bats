#!/usr/bin/env bats

load test_helper

@test "Task 2: SCRIPT_DIR resolution exists in main script" {
  run grep -q 'SCRIPT_DIR=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 2: SCRIPT_DIR uses symlink-safe resolution" {
  run grep -q 'readlink -f "$0"' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 2: Sources .toolbox from local lib directory" {
  run grep -q 'source "$SCRIPT_DIR/lib/.toolbox"' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 2: Script does not rely on SHELLTOOLSPATH" {
  run grep -q 'SHELLTOOLSPATH' "$SCRIPT_PATH"
  [ "$status" -ne 0 ]
}
