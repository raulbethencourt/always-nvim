# Story 1.1: Project Structure, Configuration & Backend Detection

Status: complete

## Story

As a user,
I want the project scaffolded with a main script that loads the shell library, parses configuration with sensible defaults, handles `--help`/`--version` flags, and detects the correct display-server backend,
So that the tool has a fully configured environment and correct backend before any system interactions begin.

## Acceptance Criteria (BDD)

1. **Given** the project has no existing source files **When** this story is implemented **Then** the following file structure exists:
   - `always-nvim` (main script with shebang, shellcheck directives, `SCRIPT_DIR` resolution)
   - `backends/x11.sh` (empty scaffold with shellcheck directives and contract comment header)
   - `backends/wayland.sh` (empty scaffold with shellcheck directives and contract comment header)
   - `config` (default config reference with all `NA_*` variables)

2. **Given** `$SHELLTOOLSPATH` is set in the environment **When** the script starts **Then** it resolves `SCRIPT_DIR` via symlink-safe `$(cd "$(dirname "$0")" && pwd)` and sources `"$SHELLTOOLSPATH"/lib/.toolbox` (ADC-5, init steps 1-2)

3. **Given** `$SHELLTOOLSPATH` is not set **When** the script starts **Then** it exits with a descriptive error message

4. **Given** no config file exists at `~/.config/always-nvim/config` **When** config parsing runs **Then** all `NA_*` variables are set to their defaults (FR27, D7)

5. **Given** a config file exists at `~/.config/always-nvim/config` **When** config parsing runs **Then** defaults are set first, then the config file is sourced, allowing user values to override defaults (FR26, FR28)

6. **Given** the user runs `always-nvim --help` **When** the script processes arguments at init step 3 **Then** it prints usage information and exits before any system state changes (FR38, G4)

7. **Given** the user runs `always-nvim --version` **When** the script processes arguments at init step 3 **Then** it prints the version string and exits before any system state changes (FR38, G4)

8. **Given** the script runs on an X11 session where `$WAYLAND_DISPLAY` is unset **When** backend detection executes **Then** the script sources `backends/x11.sh` (FR1, FR2)

9. **Given** the script runs on a Wayland session where `$WAYLAND_DISPLAY` is set **When** backend detection executes **Then** the script sources `backends/wayland.sh` (FR1, FR2)

10. **Given** the user has set `NA_BACKEND=x11` or `NA_BACKEND=wayland` in config **When** backend detection executes **Then** the config override takes precedence over environment variable detection (R4)

11. **Given** the backend detection uses the improved heuristic **When** `$WAYLAND_DISPLAY` is unset **Then** it falls back to checking `$XDG_SESSION_TYPE`, then `$DISPLAY` (R4)

12. **And** init steps 1-8 execute in exact order per the 14-step initialization sequence
13. **And** the script includes `# shellcheck shell=bash` directive (G3)
14. **And** all config variables use the `NA_` prefix
15. **And** defaults are set before sourcing config (not the `${VAR:-default}` anti-pattern)

## Tasks / Subtasks

- [x] Task 1: Create project file structure (AC: #1)
  - [x] 1.1: Create `always-nvim` main script with shebang `#!/bin/bash` and `# shellcheck shell=bash`
  - [x] 1.2: Create `backends/` directory
  - [x] 1.3: Create `backends/x11.sh` scaffold with shellcheck directives and 6-function contract header
  - [x] 1.4: Create `backends/wayland.sh` scaffold with shellcheck directives and 6-function contract header
  - [x] 1.5: Create `config` reference file with all `NA_*` variables and their defaults
  - [x] 1.6: Create `test/` directory
  - [x] 1.7: Create `test/test_helper.sh` empty scaffold

- [x] Task 2: Implement init steps 1-2 — SCRIPT_DIR + library sourcing (AC: #2, #3)
  - [x] 2.1: Resolve `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`
  - [x] 2.2: Check `$SHELLTOOLSPATH` is set, call `error_exit` if not (guard BEFORE sourcing)
  - [x] 2.3: Source `"$SHELLTOOLSPATH"/lib/.toolbox`

- [x] Task 3: Implement init step 3 — `--help` / `--version` (AC: #6, #7)
  - [x] 3.1: `case "$1"` pattern for `--help`, `-h`, `--version`, `-v`
  - [x] 3.2: Print usage text and exit 0 for help
  - [x] 3.3: Print version string and exit 0 for version
  - [x] 3.4: Define `VERSION` variable near top of script

- [x] Task 4: Implement init step 4 — config parsing (AC: #4, #5)
  - [x] 4.1: Set ALL defaults FIRST (before sourcing config)
  - [x] 4.2: Conditionally source `~/.config/always-nvim/config` if it exists
  - [x] 4.3: Verify all 6 `NA_*` variables have values after config load

- [x] Task 5: Implement init steps 5-8 — lock, backend detect, source, deps (AC: #8-#11, #12)
  - [x] 5.1: Acquire PID lock file at `/tmp/always-nvim.lock` (placeholder — full impl in Story 2.2)
  - [x] 5.2: Set minimal trap `trap 'rm -f "$LOCK_FILE"' EXIT` immediately after lock
  - [x] 5.3: Backend detection function with 3-tier heuristic: `NA_BACKEND` override > `$WAYLAND_DISPLAY` > `$XDG_SESSION_TYPE` > `$DISPLAY`
  - [x] 5.4: Source `"$SCRIPT_DIR/backends/${backend}.sh"`
  - [x] 5.5: Check dependencies via `check_for_cmd_in_path` per tool with `error_exit` on missing

- [x] Task 6: Create backend scaffolds with contract headers (AC: #1)
  - [x] 6.1: `backends/x11.sh` — 6 stub functions each containing `return 0` or placeholder
  - [x] 6.2: `backends/wayland.sh` — 6 stub functions each containing `return 0` or placeholder
  - [x] 6.3: Both files include contract comment block at top
  - [x] 6.4: Both files include `# shellcheck shell=bash` and `# shellcheck source=` directives

## Dev Notes

### Architecture Compliance — CRITICAL

This story implements **init steps 1-8** of the 14-step initialization order. The order is non-negotiable:

| Step | Operation | This Story? |
|------|-----------|-------------|
| 1 | `SCRIPT_DIR` resolution (symlink-safe) | YES |
| 2 | Source `.toolbox` library | YES |
| 3 | Handle `--help` / `--version` | YES |
| 4 | Parse config / env vars (defaults + source XDG config) | YES |
| 5 | Acquire lock file + set minimal trap | YES (placeholder — full in 2.2) |
| 6 | Detect backend | YES |
| 7 | Source backend file | YES |
| 8 | Check dependencies | YES |
| 9-14 | Clipboard save, trap upgrade, mode, tmpfile, launch | NO — later stories |

### Shell Library Integration — MANDATORY

The project ships with a shell library in `lib/`. The main entry point is `source "$SHELLTOOLSPATH"/lib/.toolbox` which loads all modules.

**Functions you MUST use from the library:**
- `error_exit(message, [exit_code])` — prints red "Error: message" to stderr, exits. [Source: lib/core.sh]
- `echo_error(message)` — prints red "Error: message" to stderr without exiting. [Source: lib/core.sh]
- `check_for_cmd_in_path(cmd)` — returns 0 if found/executable, 1 if not executable, 2 if not in PATH. [Source: lib/file.sh]

**Functions you MUST NOT use:**
- Do NOT use `command -v` for dependency checks — use `check_for_cmd_in_path`
- Do NOT use raw `echo "Error: ..." >&2` — use `error_exit` or `echo_error`
- Do NOT create custom error handling patterns

**Echo override awareness (ADC-6):**
The library overrides `echo()` in `core.sh` to route through `toolbox_log()`. This is verified safe — stdout behavior is identical to `builtin echo`. Backend functions can safely use `echo` for data output. No mitigation needed. However, for clipboard/data piping, ALWAYS use `printf '%s'` (V3 compliance).

### Config Variable Defaults — EXACT VALUES

```bash
NA_TERMINAL_CMD="alacritty --title always-nvim -e"
NA_BACKEND="auto"
NA_CLEAR_PRIMARY="true"
NA_FILETYPE="md"
NA_NVIM_ARGS=""
NA_PASTE_DELAY="0.2"
NA_FOCUS_DELAY="0.1"
```

**Config sourcing pattern — CORRECT:**
```bash
# Set defaults FIRST
NA_TERMINAL_CMD="alacritty --title always-nvim -e"
NA_PASTE_DELAY="0.2"
# ... all defaults ...

# Then source config (overrides defaults)
[ -f "$HOME/.config/always-nvim/config" ] && source "$HOME/.config/always-nvim/config"
```

**ANTI-PATTERN — DO NOT USE:**
```bash
NA_TERMINAL_CMD="${NA_TERMINAL_CMD:-alacritty --title always-nvim -e}"
```

### Backend Detection Heuristic — 3-TIER (R4)

```bash
detect_backend() {
    # Config override takes priority
    if [ "$NA_BACKEND" != "auto" ]; then
        printf '%s' "$NA_BACKEND"
        return 0
    fi
    # Tier 1: WAYLAND_DISPLAY
    if [ -n "$WAYLAND_DISPLAY" ]; then
        printf '%s' "wayland"
        return 0
    fi
    # Tier 2: XDG_SESSION_TYPE
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        printf '%s' "wayland"
        return 0
    fi
    # Tier 3: DISPLAY (X11 fallback)
    if [ -n "$DISPLAY" ]; then
        printf '%s' "x11"
        return 0
    fi
    # No display server detected
    error_exit "No display server detected. Set NA_BACKEND=x11 or NA_BACKEND=wayland in config."
}
```

### Dependency Check by Backend

**X11 requires:** `xclip`, `xdotool`, `nvim`, `alacritty` (or whatever `$NA_TERMINAL_CMD` uses)
**Wayland requires:** `wl-paste`, `wl-copy`, `wtype`, `hyprctl`, `jq`, `nvim`, `alacritty`

**Common deps (both backends):** `nvim` and the terminal command (extract first word from `$NA_TERMINAL_CMD`)

**Pattern:**
```bash
check_for_cmd_in_path "xclip" || error_exit "xclip is required but not found. Install: sudo apt install xclip"
```

### Backend Contract Header — MUST INCLUDE IN BOTH FILES

```bash
# shellcheck shell=bash
# shellcheck disable=SC2034

# Backend Interface Contract (ADC-1, ADC-2)
# ==========================================
# Each function follows the error contract:
#   Success: return data on stdout, exit code 0
#   Failure: exit code 1, stderr for diagnostics
#   Empty result: empty stdout, exit code 0
#
# Functions:
#   backend_get_selection()    - Return currently selected text (primary selection)
#   backend_get_clipboard()    - Return current clipboard contents
#   backend_set_clipboard()    - Set clipboard from stdin
#   backend_simulate_paste()   - Simulate Ctrl+V keystroke
#   backend_get_active_window() - Return focused window identifier (opaque handle)
#   backend_refocus_window()   - Refocus a previously saved window
```

### Lock File — PLACEHOLDER ONLY

This story creates a minimal lock file placeholder (steps 5+minimal trap). The full PID-checking lock logic is in Story 2.2. For now:

```bash
LOCK_FILE="/tmp/always-nvim.lock"
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT
```

### Naming Conventions — ENFORCEMENT RULES

| Element | Pattern | Example |
|---------|---------|---------|
| Config variables | `NA_` prefix, `UPPER_SNAKE_CASE` | `NA_PASTE_DELAY` |
| Backend functions | `backend_` prefix, `snake_case` | `backend_get_clipboard` |
| Internal variables | `lower_snake_case` | `saved_clipboard`, `tmp_file` |
| Script-level constants | `UPPER_SNAKE_CASE` | `LOCK_FILE`, `SCRIPT_DIR`, `VERSION` |
| Backend files | `lowercase.sh` in `backends/` | `backends/x11.sh` |
| Function keyword | NO `function` keyword | `my_func() {` not `function my_func() {` |

### Quoting — ALL VARIABLES MUST BE DOUBLE-QUOTED

```bash
# CORRECT
source "$SCRIPT_DIR/backends/$backend.sh"
[ -f "$TMPFILE" ] && rm -f "$TMPFILE"

# WRONG
source $SCRIPT_DIR/backends/$backend.sh
```

### Shellcheck Directives — REQUIRED IN ALL FILES

- `always-nvim`: `# shellcheck shell=bash` at top, plus `# shellcheck source=` for sourced files
- `backends/x11.sh`: `# shellcheck shell=bash`
- `backends/wayland.sh`: `# shellcheck shell=bash`
- Source directives: `# shellcheck source=backends/x11.sh` etc. where appropriate (or `disable=SC1090` for dynamic sources)

### Project Structure Notes

**Target file structure after this story:**

```
always-nvim/
├── always-nvim              # Main script (~40-50 lines for steps 1-8)
├── backends/
│   ├── x11.sh               # Scaffold: contract header + 6 stub functions
│   └── wayland.sh           # Scaffold: contract header + 6 stub functions
├── config                   # Default config reference (~10 lines)
├── lib/                     # Shell library (ALREADY EXISTS — DO NOT MODIFY)
│   ├── .toolbox
│   ├── core.sh
│   ├── file.sh
│   ├── options.sh
│   ├── ui.sh
│   ├── utils.sh
│   └── validation.sh
└── test/
    └── test_helper.sh       # Empty scaffold for future stories
```

**CRITICAL: Do NOT modify anything in `lib/`. It is an external dependency.**

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Initialization Order] — 14-step init sequence
- [Source: _bmad-output/planning-artifacts/architecture.md#Shell Library Integration] — toolbox functions
- [Source: _bmad-output/planning-artifacts/architecture.md#Config Variable Summary] — NA_* defaults
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns] — naming, quoting, error patterns
- [Source: _bmad-output/planning-artifacts/architecture.md#Risk Assessment] — R3 (lock), R4 (backend detection)
- [Source: _bmad-output/planning-artifacts/architecture.md#Interface Contract Verification] — ADC-1, ADC-2 contract
- [Source: _bmad-output/planning-artifacts/architecture.md#Updated Project Structure] — file layout
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.1] — acceptance criteria
- [Source: lib/core.sh] — error_exit(), echo_error(), echo() override
- [Source: lib/file.sh] — check_for_cmd_in_path() return codes (0, 1, 2)
- [Source: lib/.toolbox] — module load order

## Dev Agent Record

### Agent Model Used

claude-opus-4.6 (github-copilot)

### Debug Log References

No blocking issues encountered. All tasks implemented with red-green-refactor cycle.

### Completion Notes List

- Task 1: Created full project scaffold — `always-nvim` (executable, shebang, shellcheck), `backends/x11.sh`, `backends/wayland.sh`, `config`, `test/`, `test/test_helper.sh`
- Task 2: Init steps 1-2 — symlink-safe `SCRIPT_DIR` resolution, `SHELLTOOLSPATH` guard with descriptive error before sourcing `.toolbox`
- Task 3: Init step 3 — `case` statement for `--help`/`-h`/`--version`/`-v`, `VERSION` constant at top, usage function with options/config/env docs
- Task 4: Init step 4 — All 7 `NA_*` defaults set with direct assignment (no anti-pattern), conditional config source from `~/.config/always-nvim/config`
- Task 5: Init steps 5-8 — Placeholder lock file + EXIT trap, `detect_backend()` with 3-tier heuristic (config override > WAYLAND_DISPLAY > XDG_SESSION_TYPE > DISPLAY), backend file sourcing, dependency checks via `check_for_cmd_in_path` with `error_exit` on missing
- Task 6: Backend scaffolds already complete from Task 1 — both files have contract header (ADC-1, ADC-2), shellcheck directives, and 6 stub functions returning 0
- Note on SHELLTOOLSPATH guard: Used raw `echo "Error: ..." >&2` instead of `error_exit` for the SHELLTOOLSPATH check because `error_exit` is not available until the library is sourced. This is the one correct exception to the "use error_exit" rule.
- Note on NA_NVIM_ARGS: Story Dev Notes list 6 variables but `NA_FOCUS_DELAY` brings the total to 7. All 7 are implemented per the exact values specified.
- 6 test files covering all 6 tasks with 40+ individual assertions

### File List

- always-nvim (new) — Main script, init steps 1-8
- backends/x11.sh (new) — X11 backend scaffold with contract header and 6 stub functions
- backends/wayland.sh (new) — Wayland backend scaffold with contract header and 6 stub functions
- config (new) — Default config reference with all NA_* variables
- test/test_helper.sh (new) — Empty test helper scaffold
- test/run_tests.sh (new) — Lightweight pure-bash test runner
- test/test_01_file_structure.sh (new) — Task 1 tests: file structure verification
- test/test_02_init_steps_1_2.sh (new) — Task 2 tests: SCRIPT_DIR, SHELLTOOLSPATH guard, library sourcing
- test/test_03_help_version.sh (new) — Task 3 tests: --help, -h, --version, -v, VERSION variable
- test/test_04_config_parsing.sh (new) — Task 4 tests: defaults-first pattern, anti-pattern check, config sourcing
- test/test_05_lock_backend_deps.sh (new) — Task 5 tests: lock file, detect_backend 3-tier heuristic, init order, dependency checks
- test/test_06_backend_scaffolds.sh (new) — Task 6 tests: contract headers, 6 functions, shellcheck directives, sourceable

## Change Log

- 2026-03-11: Story 1.1 implemented — project scaffold, init steps 1-8, backend detection, config parsing, 6 test suites (all passing)

### Code Review Changes (User Requested)

- **SHELLTOOLSPATH Removed:** The user explicitly requested removing the dependency on `SHELLTOOLSPATH`. The script now sources the library directly from `$SCRIPT_DIR/lib/.toolbox`.
    - *Impact:* `test/test_02_init_steps_1_2.sh` was updated to remove `SHELLTOOLSPATH` checks and verify local sourcing.
- **Argument Parsing:** The user replaced the standard `case` statement with the `parse_options` library function.
    - *Impact:* `test/test_03_help_version.sh` was updated to check for `parse_options` usage instead of `case`.
- **Versioning:** The user renamed `VERSION` to `NA_VERSION_TO_SHOW`.
    - *Impact:* `test/test_03_help_version.sh` was updated to check for this variable name.
- **Tests Updated:** `test/test_02_init_steps_1_2.sh` and `test/test_03_help_version.sh` were rewritten to align with these new requirements. All tests pass.

