#!/usr/bin/env bats

load test_helper

@test "Task 5.1: Lock file variable defined and correct" {
  run grep -q 'LOCK_FILE=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
  run grep -q '/tmp/always-nvim-\$EUID.lock' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 5.2: Minimal EXIT trap set for lock file" {
  run grep -q "trap.*rm.*LOCK_FILE.*EXIT" "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 5.3: detect_backend function defined" {
  run grep -q 'detect_backend' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 5.3: 3-tier heuristic structure present" {
  run grep -q 'NA_BACKEND' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
  run grep -q 'WAYLAND_DISPLAY' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
  run grep -q 'XDG_SESSION_TYPE' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
  run grep -q 'DISPLAY' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 5.4: Backend file is sourced" {
  run grep -q 'source.*backends/' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 5.5: Dependency checking uses check_for_cmd_in_path" {
  run grep -q 'check_for_cmd_in_path' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

# Helper to source detect_backend function and run it
run_detect_backend() {
  # Extract function from script
  local func_def
  func_def=$(sed -n "/^detect_backend()/,/^}/p" "$SCRIPT_PATH")

  # Mock error_exit if not available or needed
  local mock_error="error_exit() { echo \"Error: \$1\"; return 1; }"

  bash -c "$mock_error; $func_def; detect_backend"
}

@test "AC #8: Detects x11 when WAYLAND_DISPLAY unset, DISPLAY set" {
  export NA_BACKEND="auto"
  export WAYLAND_DISPLAY=""
  export XDG_SESSION_TYPE=""
  export DISPLAY=":0"

  run run_detect_backend
  [ "$status" -eq 0 ]
  [ "$output" = "x11" ]
}

@test "AC #9: Detects wayland when WAYLAND_DISPLAY set" {
  export NA_BACKEND="auto"
  export WAYLAND_DISPLAY="wayland-0"
  export DISPLAY=":0"
  export XDG_SESSION_TYPE=""

  run run_detect_backend
  [ "$status" -eq 0 ]
  [ "$output" = "wayland" ]
}

@test "AC #10: NA_BACKEND override takes precedence" {
  export NA_BACKEND="x11"
  export WAYLAND_DISPLAY="wayland-0"

  run run_detect_backend
  [ "$status" -eq 0 ]
  [ "$output" = "x11" ]

  export NA_BACKEND="wayland"
  export WAYLAND_DISPLAY=""
  export DISPLAY=":0"

  run run_detect_backend
  [ "$status" -eq 0 ]
  [ "$output" = "wayland" ]
}

@test "AC #11: XDG_SESSION_TYPE fallback works" {
  export NA_BACKEND="auto"
  export WAYLAND_DISPLAY=""
  export DISPLAY=""
  export XDG_SESSION_TYPE="wayland"

  run run_detect_backend
  [ "$status" -eq 0 ]
  [ "$output" = "wayland" ]
}

@test "detect_backend fails when no display server detected" {
  export NA_BACKEND="auto"
  export WAYLAND_DISPLAY=""
  export DISPLAY=""
  export XDG_SESSION_TYPE=""

  run run_detect_backend
  [ "$status" -ne 0 ]
}

@test "AC #12: Init order - lock (5) -> backend detect (6) -> source (7)" {
  local lock_line
  lock_line=$(grep -n 'LOCK_FILE=' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  local detect_line=$(grep -n 'detect_backend' "$SCRIPT_PATH" | grep -v '^[[:space:]]*#' | grep -v 'function\|detect_backend()' | head -1 | cut -d: -f1)
  # Using 'detect_backend)' or similar to find usage, but 'backend=' assignment is better
  local detect_usage_line
  detect_usage_line=$(grep -n 'backend=\$(detect_backend)' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  local source_backend_line
  source_backend_line=$(grep -n 'source.*backends/' "$SCRIPT_PATH" | head -1 | cut -d: -f1)

  # Check if lines were found
  [ -n "$lock_line" ]
  [ -n "$detect_usage_line" ]
  [ -n "$source_backend_line" ]

  # Check order
  [ "$lock_line" -lt "$detect_usage_line" ]
  [ "$detect_usage_line" -lt "$source_backend_line" ]
}
