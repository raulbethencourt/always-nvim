#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016
# test/19_install_script.bats — Install script tests (Story 3.1)

load test_helper

# ── Structural Tests ──────────────────────────────────────────────────────────

@test "install: has shellcheck directive" {
  grep -q '# shellcheck shell=bash' "$PROJECT_ROOT/install.sh"
}

@test "install: has shebang" {
  head -1 "$PROJECT_ROOT/install.sh" | grep -q '#!/bin/bash'
}

@test "install: does not use function keyword" {
  ! grep -qE '^\s*function\s+' "$PROJECT_ROOT/install.sh"
}

# ── Functional Tests ─────────────────────────────────────────────────────────

@test "install: copies always-nvim to install dir" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -f "$test_home/.local/bin/always-nvim" ]
  [ -x "$test_home/.local/bin/always-nvim" ]

  rm -rf "$test_home"
}

@test "install: copies backend files to install dir" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -f "$test_home/.local/bin/backends/x11.sh" ]
  [ -f "$test_home/.local/bin/backends/wayland.sh" ]

  rm -rf "$test_home"
}

@test "install: copies lib directory to install dir" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -f "$test_home/.local/bin/lib/.toolbox" ]
  [ -f "$test_home/.local/bin/lib/core.sh" ]

  rm -rf "$test_home"
}

@test "install: creates config dir and example config when none exists" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -d "$test_home/.config/always-nvim" ]
  [ -f "$test_home/.config/always-nvim/config" ]

  rm -rf "$test_home"
}

@test "install: example config has all NA_ variables commented" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  grep -q '# NA_TERMINAL_CMD=' "$test_home/.config/always-nvim/config"
  grep -q '# NA_BACKEND=' "$test_home/.config/always-nvim/config"
  grep -q '# NA_CLEAR_PRIMARY=' "$test_home/.config/always-nvim/config"
  grep -q '# NA_FILETYPE=' "$test_home/.config/always-nvim/config"
  grep -q '# NA_NVIM_ARGS=' "$test_home/.config/always-nvim/config"
  grep -q '# NA_PASTE_DELAY=' "$test_home/.config/always-nvim/config"
  grep -q '# NA_FOCUS_DELAY=' "$test_home/.config/always-nvim/config"

  rm -rf "$test_home"
}

@test "install: does not overwrite existing config" {
  local test_home
  test_home=$(mktemp -d)

  # Pre-create config with custom content
  mkdir -p "$test_home/.config/always-nvim"
  printf '%s\n' 'NA_FILETYPE="txt"' >"$test_home/.config/always-nvim/config"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  # Verify original content preserved
  grep -q 'NA_FILETYPE="txt"' "$test_home/.config/always-nvim/config"

  rm -rf "$test_home"
}

@test "install: output contains existing config preserved message when config exists" {
  local test_home
  test_home=$(mktemp -d)

  mkdir -p "$test_home/.config/always-nvim"
  printf '%s\n' 'NA_FILETYPE="txt"' >"$test_home/.config/always-nvim/config"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -qi 'existing config preserved\|config.*preserved\|preserv'

  rm -rf "$test_home"
}

@test "install: output contains i3 hotkey snippet" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'bindsym \$mod+e exec always-nvim'

  rm -rf "$test_home"
}

@test "install: output contains i3 floating rule" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'for_window \[title="always-nvim"\] floating enable'

  rm -rf "$test_home"
}

@test "install: output contains Hyprland hotkey snippet" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'bind = \$mainMod, E, exec, always-nvim'

  rm -rf "$test_home"
}

@test "install: output contains Hyprland floating rules" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'windowrulev2 = float,title:'

  rm -rf "$test_home"
}

@test "install: output contains PATH reminder" {
  local test_home
  test_home=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -qi 'PATH\|path'

  rm -rf "$test_home"
}

@test "install: fails when always-nvim not found next to install.sh" {
  local test_home tmpdir
  test_home=$(mktemp -d)
  tmpdir=$(mktemp -d)

  # Copy install.sh to a temp dir WITHOUT always-nvim
  cp "$PROJECT_ROOT/install.sh" "$tmpdir/install.sh"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/bin'
    bash '$tmpdir/install.sh'
  "
  [ "$status" -ne 0 ]

  rm -rf "$test_home" "$tmpdir"
}

@test "install: detects when install dir is NOT in PATH" {
  local test_home
  test_home=$(mktemp -d)
  local install_dir="$test_home/custom/bin"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$install_dir'
    # Force PATH to NOT include install dir
    export PATH='/usr/bin:/bin'
    bash '$PROJECT_ROOT/install.sh'
  "

  [ "$status" -eq 0 ]
  # Should find the warning message
  [[ "$output" == *"NOT in your PATH"* ]]

  rm -rf "$test_home"
}

@test "install: detects when always-nvim IS in PATH" {
  local test_home
  test_home=$(mktemp -d)
  local install_dir="$test_home/custom/bin"

  # We need to make sure the script thinks it's in the path.
  # Since the script installs to INSTALL_DIR, if we add INSTALL_DIR to PATH,
  # command -v should find it.

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$install_dir'
    export PATH=\"$install_dir:\$PATH\"
    bash '$PROJECT_ROOT/install.sh'
  "

  [ "$status" -eq 0 ]
  # Should find success message
  [[ "$output" == *"always-nvim is in your PATH"* ]]

  rm -rf "$test_home"
}
