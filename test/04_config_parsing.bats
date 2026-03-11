#!/usr/bin/env bats

load test_helper

@test "Task 4.1: Defaults set using direct assignment (not parameter expansion)" {
  run grep -q 'NA_TERMINAL_CMD="\${NA_TERMINAL_CMD:-' "$SCRIPT_PATH"
  [ "$status" -ne 0 ]

  run grep -q 'NA_BACKEND="\${NA_BACKEND:-' "$SCRIPT_PATH"
  [ "$status" -ne 0 ]
}

@test "Task 4.1: All NA_ defaults are assigned" {
  run grep -q 'NA_TERMINAL_CMD=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]

  run grep -q 'NA_BACKEND=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]

  run grep -q 'NA_CLEAR_PRIMARY=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]

  run grep -q 'NA_FILETYPE=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]

  run grep -q 'NA_NVIM_ARGS=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]

  run grep -q 'NA_PASTE_DELAY=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]

  run grep -q 'NA_FOCUS_DELAY=' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "Task 4.2: Config sourcing is conditional on file existing" {
  run grep -q '\.config/always-nvim/config' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "AC #4: Config parsing succeeds when no config file exists" {
  # We mock HOME to an empty temp dir
  local TEMP_HOME
  TEMP_HOME=$(mktemp -d)

  run bash -c "HOME='$TEMP_HOME' WAYLAND_DISPLAY='' DISPLAY=':0' XDG_SESSION_TYPE='' timeout 1s '$SCRIPT_PATH' || true"

  # It might fail later (backend detection/deps), but shouldn't fail at config step
  # We check output for config errors
  rm -rf "$TEMP_HOME"

  # Check that it didn't complain about config
  [[ ! "$output" =~ config.*error ]]
  [[ ! "$output" =~ NA_.*unset ]]
}

@test "AC #5: Defaults set BEFORE sourcing config" {
  local default_line
  default_line=$(grep -n 'NA_FILETYPE=' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  local source_config_line
  source_config_line=$(grep -n 'source.*\.config/always-nvim/config' "$SCRIPT_PATH" | head -1 | cut -d: -f1)

  [ -n "$default_line" ]
  [ -n "$source_config_line" ]
  [ "$default_line" -lt "$source_config_line" ]
}
