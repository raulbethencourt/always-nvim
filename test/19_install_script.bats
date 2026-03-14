#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016
# test/19_install_script.bats — Install script tests (Story 3.1 + 3.2)

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

# ── Functional Tests — File Installation ─────────────────────────────────────

@test "install: copies always-nvim to install dir" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -f "$test_home/.local/share/always-nvim/always-nvim" ]
  [ -x "$test_home/.local/share/always-nvim/always-nvim" ]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: copies backend files to install dir" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -f "$test_home/.local/share/always-nvim/backends/x11.sh" ]
  [ -f "$test_home/.local/share/always-nvim/backends/wayland.sh" ]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: copies lib directory to install dir" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -f "$test_home/.local/share/always-nvim/lib/.toolbox" ]
  [ -f "$test_home/.local/share/always-nvim/lib/core.sh" ]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: creates config dir and example config when none exists" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -d "$test_home/.config/always-nvim" ]
  [ -f "$test_home/.config/always-nvim/config" ]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: example config has all NA_ variables commented" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
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

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: does not overwrite existing config" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  # Pre-create config with custom content
  mkdir -p "$test_home/.config/always-nvim"
  printf '%s\n' 'NA_FILETYPE="txt"' >"$test_home/.config/always-nvim/config"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  # Verify original content preserved
  grep -q 'NA_FILETYPE="txt"' "$test_home/.config/always-nvim/config"

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: output contains existing config preserved message when config exists" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  mkdir -p "$test_home/.config/always-nvim"
  printf '%s\n' 'NA_FILETYPE="txt"' >"$test_home/.config/always-nvim/config"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -qi 'existing config preserved\|config.*preserved\|preserv'

  rm -rf "$test_home" "$symlink_dir"
}

# ── Functional Tests — WM Snippets ──────────────────────────────────────────

@test "install: output contains i3 hotkey snippet" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'bindsym \$mod+e exec'

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: output contains i3 floating rule" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'for_window \[class="always-nvim"\] floating enable'

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: output contains Hyprland hotkey snippet" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'bind = \$mainMod, E, exec, always-nvim'

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: output contains Hyprland floating rules" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'windowrulev2 = float,title:'

  rm -rf "$test_home" "$symlink_dir"
}

# ── Functional Tests — Error Handling ────────────────────────────────────────

@test "install: fails when always-nvim not found next to install.sh" {
  local test_home tmpdir symlink_dir
  test_home=$(mktemp -d)
  tmpdir=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  # Copy install.sh to a temp dir WITHOUT always-nvim
  cp "$PROJECT_ROOT/install.sh" "$tmpdir/install.sh"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$tmpdir/install.sh'
  "
  [ "$status" -ne 0 ]

  rm -rf "$test_home" "$tmpdir" "$symlink_dir"
}

# ── Functional Tests — PATH Check ───────────────────────────────────────────

@test "install: output contains PATH reminder" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -qi 'PATH\|path'

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: detects when install dir is NOT in PATH" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    # Force PATH to NOT include symlink dir
    export PATH='/usr/bin:/bin'
    bash '$PROJECT_ROOT/install.sh'
  "

  [ "$status" -eq 0 ]
  # Should find the warning message
  [[ "$output" == *"NOT in your PATH"* ]]
  # Specific message for existing symlink (test creates it)
  [[ "$output" == *"symlink at $symlink_dir/always-nvim exists"* ]]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: correct message when PATH missing and symlink failed" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)
  
  # Make symlink dir unwritable to fail creation (simulates failure)
  chmod 500 "$symlink_dir"

  run bash -c "
    # Mock sudo to ensure failure without interactive prompt
    mkdir -p '$test_home/mock-bin'
    echo '#!/bin/bash' > '$test_home/mock-bin/sudo'
    echo 'exit 1' >> '$test_home/mock-bin/sudo'
    chmod +x '$test_home/mock-bin/sudo'

    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    export PATH='$test_home/mock-bin:/usr/bin:/bin'
    bash '$PROJECT_ROOT/install.sh'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"NOT in your PATH"* ]]
  # Specific message for missing symlink
  [[ "$output" == *"symlink creation failed or was skipped"* ]]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: detects when always-nvim IS in PATH" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    export PATH=\"$symlink_dir:\$PATH\"
    bash '$PROJECT_ROOT/install.sh'
  "

  [ "$status" -eq 0 ]
  # Should find success message
  [[ "$output" == *"always-nvim is in your PATH"* ]]

  rm -rf "$test_home" "$symlink_dir"
}

# ── Functional Tests — Symlink Creation (Story 3.2) ─────────────────────────

@test "install: creates symlink in SYMLINK_DIR" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -L "$symlink_dir/always-nvim" ]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: symlink points to correct target" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ "$(readlink -f "$symlink_dir/always-nvim")" = "$test_home/.local/share/always-nvim/always-nvim" ]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: symlink is updated on re-install (idempotent)" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  # First install
  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -L "$symlink_dir/always-nvim" ]

  # Second install (re-install) — should not fail
  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [ -L "$symlink_dir/always-nvim" ]
  [ "$(readlink -f "$symlink_dir/always-nvim")" = "$test_home/.local/share/always-nvim/always-nvim" ]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: warns if running as root" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  # Use fakeroot to simulate root privileges if available, or skip
  if ! command -v fakeroot >/dev/null; then
    skip "fakeroot not installed"
  fi

  run fakeroot bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    # Simulate 'n' to interactive prompt
    echo 'n' | bash '$PROJECT_ROOT/install.sh'
  "

  [ "$status" -ne 0 ]
  [[ "$output" == *"Running as root!"* ]]
  [[ "$output" == *"Aborted by user"* ]]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: fails if install parent dir unwritable" {
  local test_home symlink_dir unwritable_parent
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)
  unwritable_parent=$(mktemp -d)
  chmod 500 "$unwritable_parent"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$unwritable_parent/subdir/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  
  [ "$status" -ne 0 ]
  # Message differs depending on if parent exists or not
  [[ "$output" == *"Cannot write to"* || "$output" == *"Cannot create directories in"* ]]

  rm -rf "$test_home" "$symlink_dir" "$unwritable_parent"
}

# ── Functional Tests — Old Location Detection (Story 3.2) ───────────────────

@test "install: warns when old install location detected" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  # Pre-create old install location with a real file (not a symlink)
  mkdir -p "$test_home/.local/bin"
  printf '%s\n' '#!/bin/bash' >"$test_home/.local/bin/always-nvim"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"Old installation detected"* ]]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: no old location warning when old files do not exist" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [[ "$output" != *"Old installation detected"* ]]

  rm -rf "$test_home" "$symlink_dir"
}

@test "install: no old location warning when old path is a symlink" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  # Create a symlink at old location (not a real file) — should NOT trigger warning
  mkdir -p "$test_home/.local/bin"
  ln -s "/nonexistent/target" "$test_home/.local/bin/always-nvim"

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  [[ "$output" != *"Old installation detected"* ]]

  rm -rf "$test_home" "$symlink_dir"
}

# ── Functional Tests — Runtime Symlink Resolution (Story 3.2 Task 5) ────────

@test "install: symlink resolves to correct SCRIPT_DIR via readlink -f" {
  local test_home symlink_dir
  test_home=$(mktemp -d)
  symlink_dir=$(mktemp -d)

  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_home/.local/share/always-nvim'
    export SYMLINK_DIR='$symlink_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]

  # Simulate the main script's SCRIPT_DIR resolution via the symlink
  local resolved_path resolved_dir
  resolved_path="$(readlink -f "$symlink_dir/always-nvim")"
  resolved_dir="$(cd "$(dirname "$resolved_path")" && pwd)"

  # SCRIPT_DIR should resolve to the install dir
  [ "$resolved_dir" = "$test_home/.local/share/always-nvim" ]
  # lib/.toolbox should be findable relative to SCRIPT_DIR
  [ -f "$resolved_dir/lib/.toolbox" ]
  # backends should be findable relative to SCRIPT_DIR
  [ -f "$resolved_dir/backends/x11.sh" ]
  [ -f "$resolved_dir/backends/wayland.sh" ]

  rm -rf "$test_home" "$symlink_dir"
}
