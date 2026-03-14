#!/usr/bin/env bats
# shellcheck disable=SC2314

load test_helper

# ── Story 1.5: Terminal Spawn & Neovim Orchestration ────────────────────────
# Tests init step 14: terminal launch with nvim, synchronous blocking, exit code

# ── Structural tests ────────────────────────────────────────────────────────

@test "terminal-spawn: init step 14 comment exists after step 13" {
  local step13_line step14_line
  step13_line=$(grep -n "Init Step 13" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  step14_line=$(grep -n "Init Step 14" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$step13_line" ]
  [ -n "$step14_line" ]
  [ "$step13_line" -lt "$step14_line" ]
}

@test "terminal-spawn: launch uses NA_TERMINAL_CMD with nvim" {
  grep -q 'NA_TERMINAL_CMD.*nvim' "$SCRIPT_PATH"
}

@test "terminal-spawn: launch includes nvim_args and tmpfile" {
  grep -q 'nvim.*nvim_args.*tmpfile' "$SCRIPT_PATH"
}

@test "terminal-spawn: neovim exit code captured in nvim_exit" {
  grep -q 'nvim_exit=\$?' "$SCRIPT_PATH"
}

@test "terminal-spawn: no background processes in launch line" {
  # The launch line should NOT have & at the end (synchronous)
  local launch_line
  launch_line=$(grep 'NA_TERMINAL_CMD.*nvim' "$SCRIPT_PATH" | grep -v '^\s*#')
  [ -n "$launch_line" ]
  ! echo "$launch_line" | grep -q '&\s*$'
}

# ── Behavioral tests ────────────────────────────────────────────────────────

@test "terminal-spawn: command includes NA_TERMINAL_CMD, nvim, args array, and tmpfile in correct order" {
  # Extract the actual launch line (non-comment) and verify token ordering
  local launch_line
  launch_line=$(grep 'NA_TERMINAL_CMD.*nvim' "$SCRIPT_PATH" | grep -v '^\s*#')
  # Verify the command structure: $NA_TERMINAL_CMD nvim "${nvim_args[@]}" "$tmpfile"
  echo "$launch_line" | grep -qE '\$NA_TERMINAL_CMD\s+nvim\s+.*nvim_args.*\$tmpfile'
}

@test "terminal-spawn: SC2086 intentionally disabled for NA_TERMINAL_CMD word-splitting" {
  # The shellcheck disable for SC2086 must appear immediately before the launch line
  local launch_line disable_line
  launch_line=$(grep -n '^\$NA_TERMINAL_CMD.*nvim' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$launch_line" ]
  # Check the line immediately above the launch is a SC2086 disable
  disable_line=$((launch_line - 1))
  sed -n "${disable_line}p" "$SCRIPT_PATH" | grep -q 'shellcheck disable=.*SC2086'
}

@test "terminal-spawn: nvim_exit used in post-edit conditional" {
  # nvim_exit must be checked after capture — verifying the value flows into the paste decision
  local capture_line check_line
  capture_line=$(grep -n 'nvim_exit=\$?' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  check_line=$(grep -n 'nvim_exit.*-eq.*0' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$capture_line" ]
  [ -n "$check_line" ]
  [ "$capture_line" -lt "$check_line" ]
}

@test "terminal-spawn: NVIM_APPNAME export placed before terminal launch" {
  local appname_line launch_line
  appname_line=$(grep -n 'export NVIM_APPNAME' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  launch_line=$(grep -n '^\$NA_TERMINAL_CMD.*nvim' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$appname_line" ]
  [ -n "$launch_line" ]
  [ "$appname_line" -lt "$launch_line" ]
}
