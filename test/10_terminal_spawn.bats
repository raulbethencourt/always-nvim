#!/usr/bin/env bats
# shellcheck disable=SC2314

load test_helper

# ── Story 1.5: Terminal Spawn & Neovim Orchestration ────────────────────────
# Tests init step 14: terminal launch with nvim, synchronous blocking, exit code

@test "Story 1.5: Init step 14 comment exists after step 13" {
  local step13_line step14_line
  step13_line=$(grep -n "Init Step 13" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  step14_line=$(grep -n "Init Step 14" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$step13_line" ]
  [ -n "$step14_line" ]
  [ "$step13_line" -lt "$step14_line" ]
}

@test "Story 1.5: Terminal launch uses NA_TERMINAL_CMD" {
  grep -q 'NA_TERMINAL_CMD.*nvim' "$SCRIPT_PATH"
}

@test "Story 1.5: Terminal launch includes nvim_args and tmpfile" {
  grep -q 'nvim.*nvim_args.*tmpfile' "$SCRIPT_PATH"
}

@test "Story 1.5: Neovim exit code is captured" {
  grep -q 'nvim_exit=\$?' "$SCRIPT_PATH"
}

@test "Story 1.5: No background processes (no & in launch)" {
  # The launch line should NOT have & at the end (synchronous)
  local launch_line
  launch_line=$(grep 'NA_TERMINAL_CMD.*nvim' "$SCRIPT_PATH" | grep -v '^\s*#')
  [ -n "$launch_line" ]
  ! echo "$launch_line" | grep -q '&\s*$'
}
