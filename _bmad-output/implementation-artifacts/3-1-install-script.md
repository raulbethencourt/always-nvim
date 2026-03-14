# Story 3.1: Install Script

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to run a single install script that sets up always-nvim on my machine with proper file placement, default config, and clear instructions for my window manager,
So that I can go from download to working hotkey with minimal manual steps.

## Acceptance Criteria (BDD)

1. **Given** the user runs `./install.sh` from the repository root **When** the install script executes **Then** it copies `always-nvim`, `backends/x11.sh`, `backends/wayland.sh` to a user-accessible location on `$PATH` (FR29)

2. **Given** the install script runs **When** the config directory does not exist **Then** it creates `~/.config/always-nvim/` and writes an example `config` file with all `NA_*` variables commented with their defaults (FR30)

3. **Given** the install script runs **When** the config directory already exists **Then** it does not overwrite the existing config file (preserves user customizations)

4. **Given** the install script completes file operations **When** it displays post-install instructions **Then** it shows WM hotkey configuration snippets for both i3 (`bindsym $mod+e exec always-nvim`) and Hyprland (`bind = $mainMod, E, exec, always-nvim`) (FR31)

5. **Given** the install script displays WM instructions **When** the user reads the output **Then** it also shows window floating rules for both i3 (`for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center`) and Hyprland (`windowrulev2 = float,title:^(always-nvim)$` etc.) (FR31)

6. **And** the install script includes `# shellcheck shell=bash` directive (G3)
7. **And** the script uses `echo_error()` from the shell library for error messages if the library is available, otherwise falls back to plain stderr

## Senior Developer Review (AI)

**Review Outcome:** Changes Requested
**Review Date:** 2026-03-13

### Action Items

- [x] [AI-Review][High] Add `set -e` or check exit codes for file operations (mkdir, cp). Currently script continues if copy fails.
- [x] [AI-Review][Medium] Fix PATH check logic: strict string matching `case ":$PATH:"` fails if PATH contains unexpanded tildes or variables, or if `INSTALL_DIR` is not absolute.
- [x] [AI-Review][Low] Ensure `cp -r "$SCRIPT_DIR/lib/."` copies hidden files correctly (if any exist besides `.toolbox`). Consider more robust copy or explicit glob.

### Severity Breakdown
- **High:** 1
- **Medium:** 1
- **Low:** 1

### Detailed Findings

1. **Error Handling (High):** The script lacks `set -e` and doesn't check exit codes of `cp` or `mkdir`. If `~/.local/bin` is not writable (e.g. owned by root), the script will print "Installed..." misleadingly.
2. **PATH Check (Medium):** The case statement `*":$INSTALL_DIR:"*)` assumes `INSTALL_DIR` matches exactly what's in PATH. If user has `export PATH="$HOME/.local/bin:$PATH"` and `INSTALL_DIR` resolves to `/home/user/.local/bin`, this check might work because bash exports expanded PATH. But relying on exact string match is brittle. A better check is `if command -v always-nvim >/dev/null; then ...` *after* installation, but that checks if it's runnable, not if the specific dir is in path. The current check is acceptable but could be more robust.
3. **Hidden Files (Low):** `cp -r source/. dest/` is standard for content copying, but verifying it picks up `.toolbox` is crucial. The tests verify `.toolbox` is copied, so this is likely fine, just worth double-checking cross-shell behavior.

## Tasks / Subtasks

- [x] Task 1: Create `install.sh` with header and safety checks (AC: #6, #7)
  - [x] 1.1: Add shebang `#!/bin/bash`, `# shellcheck shell=bash`, brief description comment
  - [x] 1.2: Resolve `SCRIPT_DIR` (same symlink-safe pattern as main script)
  - [x] 1.3: Source `lib/.toolbox` if available for `echo_error()`, else define stderr fallback
  - [x] 1.4: Verify running from repo root (check `always-nvim` file exists)

### Review Follow-ups (AI)
- [x] [AI-Review][High] Add `set -e` or check exit codes for file operations (mkdir, cp). Currently script continues if copy fails.
- [x] [AI-Review][Medium] Fix PATH check logic: strict string matching `case ":$PATH:"` fails if PATH contains unexpanded tildes or variables, or if `INSTALL_DIR` is not absolute.
- [x] [AI-Review][Low] Ensure `cp -r "$SCRIPT_DIR/lib/."` copies hidden files correctly (if any exist besides `.toolbox`). Consider more robust copy or explicit glob.

- [x] Task 2: Install files to `~/.local/bin/` (AC: #1)
  - [x] 2.1: Set `INSTALL_DIR="$HOME/.local/bin"` — XDG standard user binary location
  - [x] 2.2: Create `$INSTALL_DIR` if it doesn't exist
  - [x] 2.3: Create `$INSTALL_DIR/backends/` directory
  - [x] 2.4: Copy `always-nvim` to `$INSTALL_DIR/` with `chmod +x`
  - [x] 2.5: Copy `backends/x11.sh` and `backends/wayland.sh` to `$INSTALL_DIR/backends/`
  - [x] 2.6: Copy `lib/` directory to `$INSTALL_DIR/lib/`
  - [x] 2.7: Print success message for each file copied

- [x] Task 3: Create config directory and example config (AC: #2, #3)
  - [x] 3.1: Set `CONFIG_DIR="$HOME/.config/always-nvim"`
  - [x] 3.2: Create `$CONFIG_DIR` if it doesn't exist
  - [x] 3.3: If `$CONFIG_DIR/config` does NOT exist, write example config with ALL `NA_*` variables commented out (showing defaults as comments)
  - [x] 3.4: If `$CONFIG_DIR/config` already exists, print "existing config preserved" message — DO NOT overwrite

- [x] Task 4: Display post-install WM instructions (AC: #4, #5)
  - [x] 4.1: Print i3 hotkey snippet: `bindsym $mod+e exec always-nvim`
  - [x] 4.2: Print i3 floating rule: `for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center`
  - [x] 4.3: Print Hyprland hotkey snippet: `bind = $mainMod, E, exec, always-nvim`
  - [x] 4.4: Print Hyprland floating rules: `windowrulev2 = float,title:^(always-nvim)$` and size/center rules
  - [x] 4.5: Print reminder to ensure `~/.local/bin` is in `$PATH`

- [x] Task 5: Create install script tests `test/19_install_script.bats` (AC: all)
  - [x] 5.1: Structural: `install.sh` has shellcheck directive
  - [x] 5.2: Functional: install copies files to target directory
  - [x] 5.3: Functional: install creates config dir and example config
  - [x] 5.4: Functional: install does NOT overwrite existing config
  - [x] 5.5: Functional: install output contains i3 and Hyprland snippets
  - [x] 5.6: Functional: install output contains floating window rules
  - [x] 5.7: Run full test suite — 0 regressions

## Dev Notes

### CRITICAL: Line Budget Clarification

**NFR12 (300-line budget) applies to always-nvim's runtime codebase** — the main script + backends. The architecture doc states: "The ~300 line budget in the PRD applies to always-nvim's own code; library lines are external" [Source: architecture.md line 100].

**`install.sh` is a development/distribution tool, NOT runtime code.** It is NOT counted against NFR12. The install script has no line limit, but should be kept concise (target ~60-80 lines).

**Current runtime budget:** 271/300 lines used (29 remaining). This story does NOT consume any of those 29 lines.

### Install Location: `~/.local/bin/`

Per XDG Base Directory specification, `~/.local/bin/` is the standard user-local binary directory. Most modern distros include it in `$PATH` by default. The script should:
- Use `INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"` to allow override
- Warn if `$INSTALL_DIR` is not in `$PATH`

### File Copy Strategy

The main script resolves `SCRIPT_DIR` at line 12: `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`. It then sources:
- `$SCRIPT_DIR/lib/.toolbox` (line 15)
- `$SCRIPT_DIR/backends/${backend}.sh` (line 85)

This means the install must preserve the directory structure relative to the `always-nvim` binary:
```
~/.local/bin/
├── always-nvim          # Main script (executable)
├── backends/
│   ├── x11.sh           # X11 backend
│   └── wayland.sh       # Wayland backend
└── lib/                 # Shell toolbox library (entire directory)
    ├── .toolbox
    ├── core.sh
    ├── file.sh
    ├── options.sh
    ├── ui.sh
    ├── utils.sh
    └── validation.sh
```

### Example Config File Content

The example config written to `~/.config/always-nvim/config` should have ALL variables commented out (so defaults from the script apply), with the default value shown:

```bash
# always-nvim configuration
# Uncomment and edit variables to override defaults

# Terminal command (must accept -e flag for command execution)
# NA_TERMINAL_CMD="alacritty --title always-nvim -e"

# Force backend: auto, x11, or wayland
# NA_BACKEND="auto"

# Clear primary selection after each run
# NA_CLEAR_PRIMARY="true"

# Temp file extension / Neovim filetype
# NA_FILETYPE="md"

# Additional args passed to Neovim
# NA_NVIM_ARGS=""

# Seconds to wait after paste before clipboard restore
# NA_PASTE_DELAY="0.2"

# Seconds to wait after refocus before paste
# NA_FOCUS_DELAY="0.1"
```

### WM Snippet Content (exact strings from epics.md)

**i3:**
```
# Add to ~/.config/i3/config
bindsym $mod+e exec always-nvim

# Floating window rule
for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center
```

**Hyprland:**
```
# Add to ~/.config/hypr/hyprland.conf
bind = $mainMod, E, exec, always-nvim

# Floating window rules
windowrulev2 = float,title:^(always-nvim)$
windowrulev2 = size 800 600,title:^(always-nvim)$
windowrulev2 = center,title:^(always-nvim)$
windowrulev2 = pin,title:^(always-nvim)$
```

### Library Sourcing for Error Messages (AC #7)

The install script should try to source `lib/.toolbox` for `echo_error()`. If it fails (e.g., running from a partial checkout), fall back to:
```bash
echo_error() { printf '%s\n' "ERROR: $*" >&2; }
```

### Testing Strategy

Tests go in `test/19_install_script.bats`. Use a temp directory as `INSTALL_DIR` and `HOME` to avoid polluting the real system. Pattern:
```bash
@test "install: description" {
  local test_home test_install_dir
  test_home=$(mktemp -d)
  test_install_dir="$test_home/.local/bin"

  # Run install.sh with overridden paths
  run bash -c "
    export HOME='$test_home'
    export INSTALL_DIR='$test_install_dir'
    bash '$PROJECT_ROOT/install.sh'
  "
  [ "$status" -eq 0 ]
  # assertions...

  rm -rf "$test_home"
}
```

**IMPORTANT:** The install script must respect `INSTALL_DIR` env var override for testability.

### Anti-Patterns to AVOID

1. **DO NOT** modify `always-nvim` or any backend file — this story creates `install.sh` only
2. **DO NOT** use `sudo` or install to system paths (`/usr/local/bin`) — user-local only
3. **DO NOT** overwrite existing config files — always check first
4. **DO NOT** use `cp -r` without ensuring target dir exists first
5. **DO NOT** use `echo` for data output — use `printf '%s'` per V3 convention
6. **DO NOT** hardcode paths — use variables derived from `SCRIPT_DIR` and `HOME`
7. **DO NOT** use `function` keyword — use `name()` syntax
8. **DO NOT** forget to copy `lib/` — the main script REQUIRES it at runtime

### Project Structure Notes

- `install.sh` — CREATE: install script at repo root
- `test/19_install_script.bats` — CREATE: install script tests
- `always-nvim` — DO NOT MODIFY
- `backends/*.sh` — DO NOT MODIFY
- `test/test_helper.sh` — DO NOT MODIFY
- All existing test files — DO NOT MODIFY

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.1] — Full acceptance criteria (lines 609-638)
- [Source: _bmad-output/planning-artifacts/epics.md#FR29-FR31] — Install script functional requirements (lines 52-54)
- [Source: _bmad-output/planning-artifacts/epics.md#NFR12] — 300-line budget scope (line 76)
- [Source: _bmad-output/planning-artifacts/architecture.md#line 100] — Budget applies to runtime code only
- [Source: _bmad-output/planning-artifacts/architecture.md#Config Variable Summary] — All NA_* variables and defaults (lines 316-324)
- [Source: _bmad-output/planning-artifacts/architecture.md#Development Workflow] — WM rule snippets (lines 654-655)
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure] — File layout (lines 509-546)
- [Source: always-nvim line 12] — SCRIPT_DIR resolution pattern
- [Source: always-nvim line 15] — lib/.toolbox sourcing
- [Source: always-nvim line 85] — backends/ sourcing pattern
- [Source: always-nvim lines 35-41] — All NA_* defaults
- [Source: config] — Reference config file (12 lines)

### Previous Story Intelligence (from Story 2.3)

- Agent model: claude-opus-4.6 (github-copilot) — same model for all stories
- Test file naming: `NN_description.bats` convention, next available is `19`
- Functional test pattern: `bash -c "..."` with inline setup, always clean up temp dirs
- Structural test pattern: `grep -q 'pattern' "$SCRIPT_PATH"` (but for install.sh, use `$PROJECT_ROOT/install.sh`)
- BATS executable: `./test/bats/bin/bats` (not on PATH)
- All 163 existing tests pass (18 files, 01-18 with no file 12)
- Test 04 hang was fixed by setting `NA_TERMINAL_CMD` to a fake binary in test HOME config

## Dev Agent Record

### Agent Model Used

claude-opus-4.6 (github-copilot)

### Debug Log References

- Test 16 initially failed: "fails when not run from repo root" — the test used `cd /tmp && bash /abs/path/install.sh` but SCRIPT_DIR resolves from `$0` not `$PWD`, so `always-nvim` was always found. Fixed by copying only `install.sh` to a temp dir without `always-nvim`, which correctly triggers the safety check.

### Completion Notes List

- Created `install.sh` (~85 lines) at repo root — installs always-nvim, backends, and lib to `~/.local/bin/`
- Install location overridable via `INSTALL_DIR` env var for testability
- Sources `lib/.toolbox` for `echo_error()` with fallback definition if library unavailable
- Validates repo root by checking `$SCRIPT_DIR/always-nvim` exists
- Creates `~/.config/always-nvim/config` with all 7 NA_* variables commented out (showing defaults)
- Preserves existing config — prints "Existing config preserved" message, never overwrites
- Displays WM configuration snippets for i3 (hotkey + floating rule) and Hyprland (hotkey + 4 windowrulev2 rules)
- PATH check: Robust detection using `command -v` to verify installation is reachable
- Added `set -e` for safe failure on file operations
- Used `cp -a` to ensure hidden files and permissions are preserved
- Created `test/19_install_script.bats` with 18 tests (3 structural + 15 functional)
- All 181 tests pass (163 existing + 18 new), 0 regressions
- No modifications to existing source files or test files
- Runtime line budget unaffected (271/300) — `install.sh` is tooling, not counted against NFR12

### Change Log

- 2026-03-13: Story 3.1 implementation — created `install.sh` and `test/19_install_script.bats`
- 2026-03-13: Code Review fixes — added `set -e`, used `cp -a`, improved PATH check logic, added tests
- 2026-03-14: Post-implementation code review (0H/3M/3L) — fixed Task 1 parent checkbox, synced Action Items checkboxes with Review Follow-ups, corrected File List line count (~90 → 114)

### File List

- `install.sh` — CREATED: install script (114 lines)
- `test/19_install_script.bats` — CREATED: 18 tests (3 structural + 15 functional)
