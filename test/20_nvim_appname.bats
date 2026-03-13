#!/usr/bin/env bats
# shellcheck disable=SC2016

load test_helper

# ── Structural tests ────────────────────────────────────────────────────────

@test "nvim_appname: NA_NVIM_APPNAME default exists in main script" {
  run grep -q 'NA_NVIM_APPNAME=""' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "nvim_appname: NVIM_APPNAME export line exists before terminal launch" {
  # The export must appear before the terminal launch command
  local export_line
  export_line=$(grep -n 'NVIM_APPNAME' "$SCRIPT_PATH" | grep 'export' | head -1 | cut -d: -f1)
  local launch_line
  launch_line=$(grep -n '\$NA_TERMINAL_CMD nvim' "$SCRIPT_PATH" | head -1 | cut -d: -f1)

  [ -n "$export_line" ]
  [ -n "$launch_line" ]
  [ "$export_line" -lt "$launch_line" ]
}

@test "nvim_appname: export is conditional on non-empty value" {
  run grep -q '\[ -n "\$NA_NVIM_APPNAME" \] && export NVIM_APPNAME' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

# ── Functional tests ────────────────────────────────────────────────────────

@test "nvim_appname: exports NVIM_APPNAME when NA_NVIM_APPNAME is set" {
  run bash -c '
    NA_NVIM_APPNAME="test-config"
    [ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"
    printenv NVIM_APPNAME
  '
  [ "$status" -eq 0 ]
  [ "$output" = "test-config" ]
}

@test "nvim_appname: does NOT export NVIM_APPNAME when NA_NVIM_APPNAME is empty" {
  run bash -c '
    unset NVIM_APPNAME
    NA_NVIM_APPNAME=""
    [ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"
    printenv NVIM_APPNAME
  '
  [ "$status" -ne 0 ]
}

# ── Config reference file tests ─────────────────────────────────────────────

@test "nvim_appname: config reference file contains NA_NVIM_APPNAME" {
  run grep -q 'NA_NVIM_APPNAME' "$PROJECT_ROOT/config"
  [ "$status" -eq 0 ]
}

@test "nvim_appname: install.sh example config contains NA_NVIM_APPNAME" {
  run grep -q 'NA_NVIM_APPNAME' "$PROJECT_ROOT/install.sh"
  [ "$status" -eq 0 ]
}
