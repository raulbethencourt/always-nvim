#!/usr/bin/env bats

load test_helper

@test "Task 1: Project root exists" {
  [ -d "$PROJECT_ROOT" ]
}

@test "Task 1: always-nvim main script exists and is executable" {
  [ -f "$SCRIPT_PATH" ]
  [ -x "$SCRIPT_PATH" ]
}

@test "Task 1: backends directory exists" {
  [ -d "$PROJECT_ROOT/backends" ]
}

@test "Task 1: x11 backend scaffold exists" {
  [ -f "$PROJECT_ROOT/backends/x11.sh" ]
}

@test "Task 1: wayland backend scaffold exists" {
  [ -f "$PROJECT_ROOT/backends/wayland.sh" ]
}

@test "Task 1: config template exists" {
  [ -f "$PROJECT_ROOT/config" ]
}

@test "Task 1: test directory exists" {
  [ -d "$PROJECT_ROOT/test" ]
}

@test "Task 1: test_helper scaffold exists" {
  [ -f "$PROJECT_ROOT/test/test_helper.bash" ]
}
