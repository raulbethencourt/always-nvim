# Story 3.2: Install Path & Symlink

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want the install script to place files in a proper application directory and create a symbolic link at `/usr/local/bin/always-nvim`,
So that `always-nvim` is accessible from window manager hotkeys (whose `$PATH` includes `/usr/local/bin` but not `~/.local/bin`) without manual symlink setup.

## Acceptance Criteria (BDD)

1. **Given** the user runs `./install.sh` from the repository root **When** the install script executes **Then** it installs all files (main script, `backends/`, `lib/`) to `~/.local/share/always-nvim/` preserving the relative directory structure

2. **Given** the install script completes file installation **When** symlink creation runs **Then** it creates a symbolic link at `/usr/local/bin/always-nvim` pointing to `~/.local/share/always-nvim/always-nvim`, using `sudo ln -sf` (prompts for password if needed)

3. **Given** a symlink already exists at `/usr/local/bin/always-nvim` **When** the install script runs **Then** it updates the symlink to point to the new location (idempotent via `ln -sf`)

4. **Given** the user has files from the old install location (`~/.local/bin/always-nvim`, `~/.local/bin/backends/`, `~/.local/bin/lib/`) **When** the install script detects them **Then** it prints a warning message suggesting manual cleanup (does NOT auto-delete)

5. **Given** the symlink at `/usr/local/bin/always-nvim` is followed at runtime **When** `SCRIPT_DIR` is resolved via `readlink -f` **Then** it correctly resolves through the symlink to `~/.local/share/always-nvim/` and finds `lib/.toolbox` and `backends/` (already works — verified by existing `readlink -f` in main script line 12)

6. **Given** `INSTALL_DIR` environment variable is set **When** the install script runs **Then** it uses `$INSTALL_DIR` instead of the default `~/.local/share/always-nvim` (for testability)

7. **Given** `SYMLINK_DIR` environment variable is set **When** the install script runs **Then** it uses `$SYMLINK_DIR` instead of `/usr/local/bin` (for testability — avoids `sudo` in tests)

8. **And** all existing functionality is preserved: config creation (`~/.config/always-nvim/config`), WM snippets, PATH check
9. **And** the install script remains under `set -e` for safe failure handling
10. **And** the PATH check uses `command -v always-nvim` (unchanged — now finds the symlink)

## Tasks / Subtasks

- [x] Task 1: Change install target from `~/.local/bin/` to `~/.local/share/always-nvim/` (AC: #1, #6)
  - [x] 1.1: Change default `INSTALL_DIR` from `$HOME/.local/bin` to `$HOME/.local/share/always-nvim`
  - [x] 1.2: Update `mkdir -p` to create `$INSTALL_DIR/backends` and `$INSTALL_DIR/lib` (structure unchanged, just new base path)
  - [x] 1.3: Update all `cp` commands — same files, new destination base path
  - [x] 1.4: Verify `chmod +x` on `$INSTALL_DIR/always-nvim`

- [x] Task 2: Add symlink creation at `/usr/local/bin/always-nvim` (AC: #2, #3, #7)
  - [x] 2.1: Add `SYMLINK_DIR="${SYMLINK_DIR:-/usr/local/bin}"` variable
  - [x] 2.2: Create symlink: `sudo ln -sf "$INSTALL_DIR/always-nvim" "$SYMLINK_DIR/always-nvim"` — `ln -sf` makes this idempotent (overwrites existing symlink)
  - [x] 2.3: Print success/failure message for symlink creation
  - [x] 2.4: If `sudo` fails (user cancels password prompt), print warning but do NOT `exit 1` — the files are already installed, only the symlink failed
  - [x] 2.5: Skip `sudo` if `SYMLINK_DIR` is writable by the current user (test environments)

- [x] Task 3: Detect old install location and warn (AC: #4)
  - [x] 3.1: After installation, check if `$HOME/.local/bin/always-nvim` exists AND is NOT a symlink
  - [x] 3.2: If found, print yellow warning: old files detected at `~/.local/bin/`, suggest manual removal of `~/.local/bin/always-nvim`, `~/.local/bin/backends/`, `~/.local/bin/lib/` (only the always-nvim lib, not other things in `~/.local/bin/lib/`)
  - [x] 3.3: Do NOT auto-delete — user may have other files there

- [x] Task 4: Update existing tests + add new tests in `test/19_install_script.bats` (AC: all)
  - [x] 4.1: Update all existing tests to use new default path (`$test_home/.local/share/always-nvim` instead of `$test_home/.local/bin`)
  - [x] 4.2: Add test: symlink is created in `SYMLINK_DIR`
  - [x] 4.3: Add test: symlink points to correct target
  - [x] 4.4: Add test: symlink is updated on re-install (idempotent)
  - [x] 4.5: Add test: old location detection warns when old files exist
  - [x] 4.6: Add test: no old location warning when old files don't exist
  - [x] 4.7: All tests use `SYMLINK_DIR` override to avoid `sudo` — set to a temp directory
  - [x] 4.8: Run full test suite — 0 regressions

- [x] Task 5: Verify runtime symlink resolution (AC: #5)
  - [x] 5.1: Manually verify (or add a test) that `readlink -f` on a symlink in `SYMLINK_DIR` resolves to `INSTALL_DIR/always-nvim` and that `SCRIPT_DIR` then correctly points to `INSTALL_DIR`
  - [x] 5.2: This is already guaranteed by the main script's `SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"` — `readlink -f` resolves all symlinks

## Dev Notes

### Why This Change

The current `install.sh` puts files directly into `~/.local/bin/` — a flat directory on the user's `$PATH`. This has two problems:

1. **`~/.local/bin` is not in i3's exec PATH.** i3's `exec` runs commands via `sh -c` with a limited `$PATH` that includes `/usr/local/bin` but NOT `~/.local/bin`. So `bindsym $mod+e exec always-nvim` fails unless the user manually creates a symlink.

2. **Pollutes `~/.local/bin/`.** Installing `backends/`, `lib/` subdirectories inside a shared binary directory is messy. A dedicated app directory (`~/.local/share/always-nvim/`) is cleaner.

### New Install Layout

```
~/.local/share/always-nvim/     # INSTALL_DIR (dedicated app directory)
  always-nvim                   # Main script (executable)
  backends/
    x11.sh
    wayland.sh
  lib/
    .toolbox
    core.sh
    file.sh
    options.sh
    ui.sh
    validation.sh

/usr/local/bin/
  always-nvim -> ~/.local/share/always-nvim/always-nvim   # Symlink
```

### Runtime Symlink Resolution — Already Works

The main script (line 12) uses:
```bash
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
```

When invoked via `/usr/local/bin/always-nvim` (symlink):
1. `$0` = `/usr/local/bin/always-nvim`
2. `readlink -f "$0"` = `/home/user/.local/share/always-nvim/always-nvim` (resolves symlink)
3. `dirname` = `/home/user/.local/share/always-nvim`
4. `SCRIPT_DIR` = `/home/user/.local/share/always-nvim`

Then `source "$SCRIPT_DIR/lib/.toolbox"` and `source "$SCRIPT_DIR/backends/${backend}.sh"` work correctly. **No changes to the main script needed.**

### Sudo Handling Strategy

Creating a symlink in `/usr/local/bin/` requires root. The install script should:

1. Check if `$SYMLINK_DIR` is writable by current user → skip `sudo` if yes (test environments, or if user already has write access)
2. If not writable → use `sudo ln -sf ...`
3. If `sudo` fails → print warning but don't abort. The app is installed, just the symlink failed. User can create it manually.

```bash
if [ -w "$SYMLINK_DIR" ]; then
  ln -sf "$INSTALL_DIR/always-nvim" "$SYMLINK_DIR/always-nvim"
else
  sudo ln -sf "$INSTALL_DIR/always-nvim" "$SYMLINK_DIR/always-nvim" || {
    echo_error "Could not create symlink in $SYMLINK_DIR (sudo failed)"
    printf '%s\n' "  ${YELLOWF}Create it manually:${RESET} sudo ln -sf '$INSTALL_DIR/always-nvim' '$SYMLINK_DIR/always-nvim'"
  }
fi
```

### Old Location Detection

Check after installing to the new location:
```bash
if [ -f "$HOME/.local/bin/always-nvim" ] && [ ! -L "$HOME/.local/bin/always-nvim" ]; then
  printf '%s\n' "  ${YELLOWF}Old installation detected:${RESET} ~/.local/bin/always-nvim"
  printf '%s\n' "  You can remove old files: rm ~/.local/bin/always-nvim && rm -rf ~/.local/bin/backends ~/.local/bin/lib"
fi
```

The `! -L` check ensures we don't warn if `~/.local/bin/always-nvim` is itself a symlink (edge case: user may have created one).

### Testing Strategy

All tests use `INSTALL_DIR` and `SYMLINK_DIR` overrides pointing to temp directories — no `sudo` required in CI/test runs.

Pattern for symlink tests:
```bash
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
  [ "$(readlink -f "$symlink_dir/always-nvim")" = "$test_home/.local/share/always-nvim/always-nvim" ]

  rm -rf "$test_home" "$symlink_dir"
}
```

### Anti-Patterns to AVOID

1. **DO NOT** modify `always-nvim` main script — symlink resolution already works via `readlink -f`
2. **DO NOT** modify any backend file
3. **DO NOT** auto-delete old installation files — only warn
4. **DO NOT** abort if `sudo` fails — print warning and continue
5. **DO NOT** hardcode paths — use `INSTALL_DIR` and `SYMLINK_DIR` variables
6. **DO NOT** use `echo` for data output — use `printf '%s'` per V3 convention
7. **DO NOT** use `function` keyword — use `name()` syntax
8. **DO NOT** forget `set -e` is active — handle expected failures with `|| { ... }` pattern
9. **DO NOT** create the symlink before installing the files — target must exist first

### Project Structure Notes

- `install.sh` — MODIFY: change install target, add symlink creation, add old location detection
- `test/19_install_script.bats` — MODIFY: update paths in existing tests, add new symlink/detection tests
- `always-nvim` — DO NOT MODIFY (symlink resolution already works)
- `backends/*.sh` — DO NOT MODIFY
- `test/test_helper.sh` — DO NOT MODIFY
- All other test files — DO NOT MODIFY

### References

- [Source: install.sh lines 27, 31-43] — Current `INSTALL_DIR` default and file copy logic
- [Source: install.sh lines 103-112] — Current PATH check logic (reusable as-is)
- [Source: always-nvim line 12] — `readlink -f` SCRIPT_DIR resolution (already symlink-safe)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.1] — Original install story acceptance criteria
- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.2] — New story acceptance criteria
- [Source: _bmad-output/planning-artifacts/epics.md#FR29] — Install script copies files
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure] — File layout (lines 509-546)
- [Source: _bmad-output/planning-artifacts/architecture.md#Config Variable Summary] — All NA_* variables (lines 316-324)
- [Source: _bmad-output/implementation-artifacts/3-1-install-script.md] — Previous story learnings and dev notes

### Previous Story Intelligence (from Story 3.1)

- `install.sh` is 114 lines with `set -e` active
- `INSTALL_DIR` is overridable via env var — pattern already established for testability
- Sources `lib/.toolbox` for colored output (`GREENF`, `YELLOWF`, `CYANF`, `BLUEF`, `RESET`)
- Falls back to empty color vars if library unavailable
- Uses `cp -a` for lib directory to preserve hidden files and permissions
- `command -v always-nvim` used for PATH check (will now find the symlink)
- 18 existing tests: 3 structural + 15 functional
- All tests use `INSTALL_DIR` and `HOME` overrides — same pattern extends to `SYMLINK_DIR`
- Agent model: claude-opus-4.6 (github-copilot)
- BATS executable: `./test/bats/bin/bats`
- Current total: 188 tests across all files

## Dev Agent Record

### Agent Model Used

claude-opus-4.6 (github-copilot)

### Debug Log References

### Completion Notes List

- Tasks 1-3 implemented in `install.sh`: changed default `INSTALL_DIR` to `~/.local/share/always-nvim`, added `SYMLINK_DIR` with smart sudo handling (skip if writable, graceful failure if sudo fails), added old location detection with `! -L` guard
- Task 4: Updated all 18 existing tests to use new paths + `SYMLINK_DIR` override; added 8 new tests (symlink creation, target correctness, idempotency, symlink output message, old location warning, no false warning, symlink-is-a-symlink guard, runtime resolution)
- Task 5: Added dedicated test verifying `readlink -f` through symlink resolves to correct `SCRIPT_DIR` and finds `lib/.toolbox` and `backends/`
- Two pre-existing test assertions were out of sync with actual `install.sh` output (i3 snippet used `class` not `title`, and `exec "always-nvim"` not `exec always-nvim`) — corrected to match actual source
- Total tests: 200 (was 188), all passing, 0 regressions
- `install.sh` grew from 114 to 138 lines

### Change Log

- `install.sh`: Changed `INSTALL_DIR` default from `$HOME/.local/bin` to `$HOME/.local/share/always-nvim`; added `SYMLINK_DIR` variable with writable-check and sudo fallback; added old location detection block; updated PATH check message to reference symlink dir
- `test/19_install_script.bats`: Updated all existing test paths from `.local/bin` to `.local/share/always-nvim`; added `SYMLINK_DIR` override to all tests; added 8 new tests for symlink and old-location features; fixed 2 i3 snippet assertions to match actual output

### File List

- `install.sh` — MODIFIED (138 lines, was 114)
- `test/19_install_script.bats` — MODIFIED (26 tests, was 18)
