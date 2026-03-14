---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - "product-brief: _bmad-output/product-brief.md"
  - "prd: _bmad-output/prd.md"
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-03-10'
project_name: 'always-nvim'
user_name: 'Maestro'
date: '2026-03-10'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
38 FRs across 9 capability areas. The requirements describe a linear pipeline tool with two modes of operation (insert new / edit selection), differentiated by automatic primary selection detection. The backend abstraction (6-function interface contract across X11 and Wayland) is the only polymorphic boundary. All other logic is shared between backends.

Note: The original PRD specified 7 backend functions with `backend_copy_to_clipboard()` and `backend_set_clipboard()` as separate functions. Architectural analysis determined these are identical in both backends — consolidated to a single `backend_set_clipboard()` function, reducing the interface to 6 functions.

**Non-Functional Requirements:**
- Performance: <500ms hotkey-to-ready, <300ms exit-to-pasted, <50ms clipboard operations, <50MB memory
- Reliability: 100% clipboard restoration, 100% temp file cleanup, no orphan processes, stable over 100 consecutive invocations
- Compatibility: Backend parity (X11 = Wayland behavior), Alacritty default with configurable alternatives, paste into Chromium, Firefox, Slack, GTK/Qt inputs
- Maintainability: <300 lines total, <50 lines per backend, new backends require zero changes to main script

**Scale & Complexity:**

- Primary domain: CLI/Shell tooling (orchestrating external Unix tools)
- Complexity level: Low
- Estimated architectural components: 4 (main script, x11 backend, wayland backend, config)

### Technical Constraints & Dependencies

- **Bash-only**: No compilation, no external runtimes. Pure POSIX-compatible shell with bashisms allowed.
- **External tool dependency**: X11 requires xdotool + xclip; Wayland requires wl-clipboard + wtype + jq + hyprctl (Hyprland-specific)
- **Window manager cooperation**: Floating behavior and window rules are delegated to the WM config (i3/Hyprland). The script only controls the terminal window title.
- **Synchronous execution model**: Script blocks on terminal process exit. No background processes, no async operations.
- **Clipboard as transport**: Text is moved between applications via the system clipboard with save/restore. This creates a brief (~200ms) window where the user's clipboard is temporarily overwritten.

### Cross-Cutting Concerns Identified

1. **Clipboard safety**: Every code path must save and restore clipboard state. This affects the main flow, abort handling, error handling, and signal traps. The highest architectural priority.
2. **Signal handling / cleanup**: Trap handlers for EXIT, INT, TERM must ensure temp file deletion and clipboard restoration. This wraps the entire execution flow.
3. **Backend abstraction**: All system interactions (clipboard, selection, window, keystroke simulation) go through the 6-function interface. Backend selection happens once at startup and is immutable for the invocation.
4. **Error handling**: Dependency checks at startup (are required tools installed?), graceful failure on command errors, descriptive error messages to stderr.

### Architectural Decisions

**ADC-1: Backend Interface — 6 Functions (Consolidated)**
The backend interface contract is consolidated from 7 to 6 functions by merging `backend_copy_to_clipboard()` and `backend_set_clipboard()` into a single `backend_set_clipboard()`. Both had identical implementations in both backends.

Revised interface: `backend_get_selection()`, `backend_get_clipboard()`, `backend_set_clipboard()`, `backend_simulate_paste()`, `backend_get_active_window()`, `backend_refocus_window()`.

**ADC-2: Backend Error Contract**
Each backend function must follow a defined success/failure contract:
- Success: return data on stdout, exit code 0
- Failure: exit code 1, stderr for diagnostics
- Empty result (e.g., no selection): empty stdout, exit code 0
This is documented as a comment block at the top of each backend file. No framework — just convention.

**ADC-3: Trap-Based Cleanup Architecture**
Cleanup uses `trap cleanup EXIT` pattern. The cleanup function is idempotent (safe to call multiple times). Trap is set *after* clipboard state is saved, not before — preventing restore of unsaved state. Cleanup checks if `$SAVED_CLIPBOARD` is set and `$TMPFILE` exists before acting.

**ADC-4: Primary Selection Cleanup — Configurable**
New config option `NA_CLEAR_PRIMARY` (default: `true`). When enabled, the cleanup function clears the primary selection after each invocation to mitigate stale Mode B triggers. Users who want to preserve primary selection across invocations can set this to `false`.

**ADC-5: Full Toolbox Loading**
Source the full `.toolbox` at startup rather than cherry-picking individual modules. The performance cost is negligible (<5ms against a 500ms budget). The library has been pruned to project needs — 4 modules under 800 lines. Selective sourcing introduces fragility if internal module dependencies change. Simplicity wins.

**ADC-6: `echo` Override — Verified Safe**
The shell library's `core.sh` redefines `echo()` to route through `toolbox_log()`. Audit confirms: stdout behavior is identical to `builtin echo` — the override only adds optional file logging when `__TOOLBOX_LOG_OUTPUT` is set (empty by default). No interference with backend function stdout data flow. Backend functions can safely use `echo` for data output. No mitigation needed.

**ADC-7: Backend Test Strategy — Inline Mocks with Centralized Helper**
Use inline mock functions in BATS test files for V1. Backend functions are thin wrappers around system tools — the high-value test target is orchestration logic (mode detection, clipboard save/restore, cleanup). Mock functions (e.g., `backend_get_clipboard() { echo "saved"; }`) are defined in a centralized `test/test_helper.sh` file to prevent mock drift. Each test file sources the helper. Integration tests against real backends deferred to post-V1.

### Shell Library Integration

The project includes a local copy of the user's shell scripting library (`lib/`), sourced via `$SHELLTOOLSPATH`. The main entry point is `source "$SHELLTOOLSPATH"/lib/.toolbox` which loads all modules in dependency order.

**Functions directly applicable to always-nvim:**

- `error_exit()` / `echo_error()` — standardized error handling to stderr (replaces ad-hoc error patterns)
- `check_for_cmd_in_path()` — dependency verification at startup (xdotool, xclip, wl-copy, wtype, jq)
- `toolbox_log()` / logging system — optional debug logging (controlled by environment variable)
- ANSI color constants (REDF, GREENF, etc.) — for user-facing error/status messages

**Integration approach:**
- `lib/` ships with the project (already present in repo root)
- Main script sources `.toolbox` at startup, gaining access to all modules
- This replaces raw `echo` error handling with structured `error_exit()` / `echo_error()`
- Dependency checks use `check_for_cmd_in_path()` instead of manual `command -v` checks
- The ~300 line budget in the PRD applies to always-nvim's own code; library lines are external
- V1 uses env var config via `source`; CLI option parsing with `parse_options()` deferred to post-V1 (Constraint T1)
- `$SHELLTOOLSPATH` is assumed to be set in Maestro's environment; auto-detection from script location deferred to future portability work (Constraint T4)

### Testing Strategy

**Framework:** BATS (Bash Automated Testing System)
- Purpose-built for testing Bash scripts and CLI tools
- Supports setup/teardown fixtures, TAP output, and assertion helpers
- Extensions: bats-support, bats-assert, bats-file for richer assertions

**Testing scope for V1:**
- Backend interface contract verification (each of the 6 functions per backend)
- Mode detection logic (Mode A vs Mode B based on primary selection state)
- Clipboard save/restore cycle correctness
- Trap/cleanup behavior (temp file deletion, clipboard restoration)
- Dependency check behavior (missing tools produce correct errors)
- Configuration option handling (NA_CLEAR_PRIMARY, NA_TERMINAL, etc.)

**Test-first targets (from Interface Contract Verification):**
- V1: `backend_get_selection` returns exit 0 + empty stdout when no selection exists (both backends)
- V2: `backend_get_clipboard` returns exit 0 + empty stdout when clipboard is empty (both backends)
- V3: `backend_set_clipboard` preserves exact content without trailing newline addition

**Testing constraints:**
- Backend functions interact with system clipboard and window manager — integration tests require a running display server or mocking strategy
- Unit-testable logic: mode detection, config parsing, option handling, cleanup logic
- Integration-testable: full pipeline with mocked backends via `test/test_helper.sh`

### Constraint Mapping

| # | Tension | Severity | Resolution |
|---|---|---|---|
| T1 | 300-line budget vs. `parse_options()` overhead | Low | Defer CLI option parsing to post-V1. V1 uses env var config via `source`. |
| T2 | X11/Wayland parity testing vs. no CI | Low | Manual testing on both environments for V1. |
| T3 | Electron/XWayland paste edge cases | Low | Document as known limitation. Not architectural. |
| T4 | `$SHELLTOOLSPATH` portability | Low | V1 assumes Maestro's environment. Future: auto-detect from script location. |

No high-severity tensions found. All identified tensions have clear, low-cost mitigations.

### Risk Assessment

| Risk | Severity | Mitigation | Lines |
|---|---|---|---|
| **R1: Clipboard loss on crash** | 🔴 High | Persistent clipboard backup file (`/tmp/always-nvim-clipboard-backup`). Written before overwriting clipboard. Cleaned up on normal exit. Survives crashes for manual recovery. | ~3 |
| **R2: Stale temp files** | 🔴 High | `mktemp /tmp/always-nvim-XXXXXX.md` prefix + stale file cleanup on startup: `find /tmp/always-nvim-* -mmin +60 -delete 2>/dev/null` | ~2 |
| **R3: Double invocation** | 🟡 Medium | PID lock file at `/tmp/always-nvim.lock`. Check on startup, exit if PID still running. Cleanup removes lock. | ~5 |
| **R4: Backend misdetection** | 🟡 Medium | Config override `NA_BACKEND=x11\|wayland` + improved detection heuristic: check `$WAYLAND_DISPLAY` first, fall back to `$XDG_SESSION_TYPE`, then `$DISPLAY`. | ~5 |
| **R5: User abort pastes stale content** | 🟡 Medium | Check Neovim exit code. `:cq` returns non-zero → skip paste, just restore clipboard and clean up. `:wq` returns 0 → proceed with paste. | ~2 |
| R6: Dependency missing later | 🟢 Low | Already mitigated by startup dependency checks. | 0 |
| R7: Large clipboard | 🟢 Low | Accept for V1. Correctness over speed. | 0 |

**Total mitigation cost: ~17 lines.**

**P4: Empty file paste behavior:** When the user saves an empty file with `:wq` (exit 0), the script pastes empty content. This is intended behavior for V1 — the user explicitly saved, so we respect their intent. Documented, not prevented.

### Dependency Chain

#### External Dependencies by Backend

**X11:** bash (≥4.0), alacritty, nvim, xclip, xdotool + coreutils (mktemp) — **5 tools**
**Wayland:** bash (≥4.0), alacritty, nvim, wl-paste, wl-copy, wtype, hyprctl, jq + coreutils — **7 tools**

Wayland has 40% more external dependencies. `hyprctl` is Hyprland-specific and the highest upgrade-risk dependency (actively developed, IPC interface may change between versions).

#### Initialization Order (Implementation Checklist)

This is the critical sequencing. Misordering causes bugs.

| Step | Operation | Depends On | Critical Ordering |
|---|---|---|---|
| 1 | Source `.toolbox` | `$SHELLTOOLSPATH` set | Must be first — all library functions needed below |
| 2 | Parse config / env vars | Library loaded (`error_exit()`) | After step 1 |
| 3 | Acquire lock file (R3) | Nothing | **Before any system state changes** — earliest possible |
| 4 | Detect backend | `$WAYLAND_DISPLAY`, `$XDG_SESSION_TYPE`, `$DISPLAY` | After config (NA_BACKEND override) |
| 5 | Source backend file | Backend detected | After step 4 — functions undefined otherwise |
| 6 | Check dependencies | Backend sourced (to know which tools) | **After step 5** — otherwise don't know what to check |
| 7 | Save clipboard | Dependencies verified, backend available | **After step 6** — `backend_get_clipboard()` requires tools |
| 8 | Set trap EXIT | Clipboard saved | **After step 7** — cleanup must not restore unsaved state (ADC-3) |
| 9 | Stale file cleanup (R2) | mktemp prefix pattern | Non-critical ordering |
| 10 | Determine mode (A/B) | Backend functions available | After step 5 |
| 11 | Create tmpfile + pre-fill (Mode B) | Mode determined | After step 10 |
| 12 | Launch terminal + nvim | Everything above | Last step — blocks until exit |

**Critical constraints:**
- Step 8 MUST come after step 7 (ADC-3: trap after clipboard save)
- Step 6 MUST come after step 5 (need backend to know which tools to check)
- Step 3 MUST come before step 12 (lock before any long-running operation)

#### Single Points of Failure

| Component | Blast Radius | Mitigation |
|---|---|---|
| `$SHELLTOOLSPATH` unset | Total | T4: auto-detect from script location (future) |
| Backend detection wrong | Total | R4: `NA_BACKEND` config override |
| `xclip` / `wl-clipboard` unavailable | Total | Startup dependency check |
| Alacritty not installed | Total | Startup dependency check + `NA_TERMINAL` config |
| `nvim` not installed | Total | Startup dependency check |

### Interface Contract Verification

#### Contract Violations Found

| # | Interface | Issue | Severity | Required Fix |
|---|---|---|---|---|
| **V1** | `backend_get_selection()` Wayland | `wl-paste --primary` returns exit 1 on empty selection; X11 returns exit 0 | 🔴 High | Normalize: `result=$(wl-paste --primary 2>/dev/null) \|\| true; printf '%s' "$result"` |
| **V2** | `backend_get_clipboard()` Wayland | `wl-paste` returns exit 1 on empty clipboard; X11 returns exit 0 | 🔴 High | Same normalization pattern |
| **V3** | `backend_set_clipboard()` caller | Using `echo` adds trailing newline, corrupting exact clipboard restoration | 🟡 Medium | Use `printf '%s'` instead of `echo` for all clipboard pipe operations |
| **V4** | `backend_get_active_window()` Wayland | `hyprctl activewindow -j` may return `"0x0"` or `"null"` when no window focused | 🟡 Medium | Check for null/zero address, return exit 1 |
| **V5** | `backend_refocus_window()` Wayland | `hyprctl dispatch` returns exit 0 even for invalid/closed window | 🟢 Low | Document as known behavior. If source window closed during edit, paste goes nowhere. |

**V1 and V2 are the highest-priority implementation findings.** Without normalization, Mode B detection and clipboard save would fail silently on Wayland whenever selection or clipboard is empty.

#### Additional Contract Notes

- `check_for_cmd_in_path()` returns 0 (found), 1 (not executable), or 2 (not in PATH). Usage: `check_for_cmd_in_path "xclip" || error_exit "xclip required"` — the `||` catches both failure codes.
- `backend_get_active_window()` returns an **opaque window handle**. Callers must not parse, compare, or interpret it. Only valid use: pass to `backend_refocus_window()`.
- Temp file contract: use `printf '%s'` for writing selection to tmpfile (no trailing newline injection). Neovim's `fixeol` may add a trailing newline on save — documented as known behavior.

### Line Budget Allocation

| Component | Estimated Lines | Notes |
|---|---|---|
| Library sourcing + config | ~10 | Source `.toolbox`, source config file |
| Lock file (R3) | ~5 | Check/create/cleanup PID lock |
| Backend detection + sourcing | ~10 | Env var checks, source backend file |
| Dependency checks | ~10 | `check_for_cmd_in_path` per tool |
| Clipboard save + trap setup | ~8 | Save clipboard, set EXIT trap (ADC-3) |
| Mode detection + tmpfile | ~10 | Check primary selection, create/pre-fill tmpfile |
| Terminal launch + wait | ~5 | Launch Alacritty with nvim, wait |
| Exit code check + paste flow | ~15 | R5 check, read tmpfile, set clipboard, refocus, paste |
| Cleanup function | ~15 | Restore clipboard, rm tmpfile, rm lock, rm backup, clear primary |
| Stale file cleanup (R2) | ~2 | find + delete old tmpfiles |
| Clipboard backup (R1) | ~3 | Write backup before overwrite |
| **Main script total** | **~93** | Well under 300-line budget |
| Backend file (each) | ~25-30 | 6 functions + header/contract comment |
| Config file | ~10 | Default env var values |
| **Grand total** | **~160** | ~53% of budget used, ample headroom |

## Starter Template Evaluation

### Primary Technology Domain

CLI/Shell tooling — pure Bash script orchestrating external Unix tools. Falls outside the typical starter template ecosystem.

### Starter Options Considered

| Option | Description | Verdict |
|---|---|---|
| **bashly** | CLI framework generator for Bash. Creates argument parsing, subcommands, help text. | ❌ Overkill. Single-purpose script, not a multi-command CLI. Shell library's `parse_options()` available for future CLI args. |
| **bash-oo-framework** | Object-oriented Bash framework. | ❌ Philosophical mismatch. ~160 lines of procedural Bash. OO abstractions add complexity with no benefit. |
| **bats-core project template** | Template repos for BATS testing setup. | 🟡 Partially useful for test structure, but we don't need a full template. |
| **Custom from scratch** | Empty directory, create files per architecture spec. | ✅ **Best fit.** Architecture document already defines exact file structure, function signatures, initialization order, and line budgets. |

### Selected Approach: Custom From Scratch

**Rationale:** always-nvim is a ~160-line Bash script with 2 backend files, a config file, and BATS tests. No starter template exists that matches this project's structure. The architecture document already provides more precise implementation guidance than any generic Bash template could. Starting from scratch is the fastest and cleanest path.

**Project Structure:**

```
always-nvim/
├── always-nvim              # Main script (~93 lines)
├── backend-x11.sh           # X11 backend (~25-30 lines)
├── backend-wayland.sh       # Wayland backend (~25-30 lines)
├── config                   # Default config (env vars, ~10 lines)
├── lib/                     # Shell library (pruned to project needs)
│   ├── .toolbox
│   ├── core.sh
│   ├── file.sh
│   ├── options.sh
│   └── ui.sh
└── test/
    ├── test_helper.sh       # Centralized mock functions (ADC-7/P2)
    ├── test_mode_detection.bats
    ├── test_clipboard.bats
    ├── test_cleanup.bats
    └── test_backend_contract.bats  # V1-V4 regression tests (P3)
```

**Initialization:** No CLI command needed. Create files per architecture spec.

**Architectural Decisions Provided:**
- Language & Runtime: Bash ≥4.0, sourcing shell library
- Testing Framework: BATS with bats-support, bats-assert extensions
- Code Organization: Flat structure, backend files sourced by main script
- Development Experience: Run directly from repo (`./always-nvim`), tests via `bats test/`

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
All 7 decisions below are critical — each affects the main script's structure.

**Deferred Decisions (Post-V1):**
- CLI option parsing via `parse_options()` (Constraint T1)
- `$SHELLTOOLSPATH` auto-detection (Constraint T4)
- Per-invocation `--filetype` override (D3 future)

### Decisions

| # | Decision | Choice | Default | Rationale |
|---|---|---|---|---|
| D1 | Config file location & format | `~/.config/always-nvim/config`, sourced shell vars | All `NA_*` defaults in script | XDG-compliant, zero-cost parsing via `source` |
| D2 | Backend file location | `backends/` subdirectory | `$(dirname "$0")/backends/` | Clean separation; sourced as `x11.sh` / `wayland.sh` |
| D3 | Temp file filetype | Configurable `NA_FILETYPE` | `md` | `.md` suits primary use (emails, messages). Extension used in `mktemp` pattern. |
| D4 | Neovim launch arguments | Mode-aware + `NA_NVIM_ARGS` | `NA_NVIM_ARGS=""` | Mode A: `-c "startinsert"`. Mode B: normal mode. User's full Neovim config always loaded. |
| D5 | Terminal launch command | `NA_TERMINAL_CMD` template | `alacritty --title always-nvim -e` | Script appends `nvim [args] "$TMPFILE"`. Title used for WM rule matching (invisible to user). One-line config change for other terminals. |
| D6 | Clipboard restore timing | Configurable delay `NA_PASTE_DELAY` | `0.2` (seconds) | Prevents paste race condition. App processes Ctrl+V asynchronously; delay ensures edited text is read before clipboard is restored. |
| D7 | Missing config handling | Silent fallback to defaults | — | Zero friction. If config file exists, source it. If not, defaults apply. No warnings, no auto-creation. |
| D8 | Neovim config isolation | NVIM_APPNAME env var via NA_NVIM_APPNAME | (empty) | Neovim 0.9+ natively supports NVIM_APPNAME. When set, Neovim reads ~/.config/<appname>/ instead of ~/.config/nvim/. Empty default = no change. Opt-in for minimal configs. |
| D9 | Neovim server daemon | `nvim --headless --listen` + `nvim --server --remote` | disabled (`NA_SERVER_ENABLED="false"`) | Pre-warms a headless Neovim process for near-instant startup. Main script detects server socket and connects instead of cold-starting. Falls back gracefully when server unavailable. Uses NA_NVIM_APPNAME for config isolation. |

### Config Variable Summary

| Variable | Default | Description |
|---|---|---|
| `NA_TERMINAL_CMD` | `alacritty --title always-nvim -e` | Terminal launch prefix |
| `NA_BACKEND` | auto-detected | Force backend: `x11` or `wayland` (R4) |
| `NA_CLEAR_PRIMARY` | `true` | Clear primary selection after each run (ADC-4) |
| `NA_FILETYPE` | `md` | Temp file extension / Neovim filetype |
| `NA_NVIM_ARGS` | (empty) | Additional args passed to Neovim |
| `NA_PASTE_DELAY` | `0.2` | Seconds to wait after paste before clipboard restore |
| `NA_NVIM_APPNAME` | (empty) | Neovim APPNAME — uses ~/.config/<appname>/ for config (D8) |
| `NA_SERVER_ENABLED` | `false` | Enable Neovim server daemon detection (D9) |
| `NA_SERVER_SOCKET` | `/tmp/always-nvim-server.sock` | Socket path for Neovim server daemon (D9) |

### Updated Project Structure

```
always-nvim/
├── always-nvim              # Main script (~93 lines)
├── backends/
│   ├── x11.sh               # X11 backend (~25-30 lines)
│   └── wayland.sh           # Wayland backend (~25-30 lines)
├── config                   # Default config reference (~10 lines)
├── lib/                     # Shell library (pruned to project needs)
│   ├── .toolbox
│   ├── core.sh
│   ├── file.sh
│   ├── options.sh
│   └── ui.sh
└── test/
    ├── test_helper.sh
    ├── test_mode_detection.bats
    ├── test_clipboard.bats
    ├── test_cleanup.bats
    └── test_backend_contract.bats
```

## Implementation Patterns & Consistency Rules

### Naming Conventions

| Element | Pattern | Example | Anti-Pattern |
|---|---|---|---|
| Config variables | `NA_` prefix, `UPPER_SNAKE_CASE` | `NA_PASTE_DELAY` | `pasteDelay`, `PASTE_DELAY` (no prefix) |
| Backend functions | `backend_` prefix, `snake_case` | `backend_get_clipboard` | `getClipboard`, `Backend_GetClipboard` |
| Internal variables | `lower_snake_case` | `saved_clipboard`, `tmp_file` | `savedClipboard`, `TMPFILE` (reserved) |
| Script-level constants | `UPPER_SNAKE_CASE` | `LOCK_FILE`, `SCRIPT_DIR` | `lockFile`, `script_dir` |
| Backend files | `lowercase.sh` in `backends/` | `backends/x11.sh` | `backend-x11.sh`, `X11.sh` |
| Test files | `test_*.bats` | `test_clipboard.bats` | `clipboard_test.bats` |
| Test helper | `test_helper.sh` | `test/test_helper.sh` | `helpers.sh`, `common.sh` |

### Function Patterns

```bash
# ✅ CORRECT: Backend function pattern
backend_get_clipboard() {
    xclip -selection clipboard -o
}

# ❌ WRONG: Using 'function' keyword
function backend_get_clipboard() {
    xclip -selection clipboard -o
}

# ✅ CORRECT: Wayland normalization pattern (V1/V2 fix)
backend_get_selection() {
    local result
    result=$(wl-paste --primary 2>/dev/null) || true
    printf '%s' "$result"
}

# ❌ WRONG: No normalization
backend_get_selection() {
    wl-paste --primary
}
```

### Error Handling Pattern

```bash
# ✅ CORRECT: Use library functions
check_for_cmd_in_path "xclip" || error_exit "xclip is required but not found. Install: sudo apt install xclip"

# ❌ WRONG: Ad-hoc error handling
if ! command -v xclip &>/dev/null; then
    echo "Error: xclip not found" >&2
    exit 1
fi
```

### Output & Data Flow Pattern

```bash
# ✅ CORRECT: printf for data, library functions for messages
printf '%s' "$content" | backend_set_clipboard    # Data: exact content
echo_error "Backend detection failed"              # Error: to stderr via library

# ❌ WRONG: echo for data (adds trailing newline)
echo "$content" | backend_set_clipboard

# ❌ WRONG: raw echo for errors
echo "Error: detection failed" >&2
```

### Variable Scoping Pattern

```bash
# ✅ CORRECT: local variables in functions
cleanup() {
    local tmp_exists
    [ -f "$TMPFILE" ] && tmp_exists=1
    ...
}

# ❌ WRONG: global variables leaking from functions
cleanup() {
    tmp_exists=1    # Pollutes global namespace
    ...
}

# Exception: Script-level state variables ARE global (by design)
SAVED_CLIPBOARD=""
TMPFILE=""
SOURCE_WINDOW=""
```

### Quoting Pattern

```bash
# ✅ CORRECT: Always double-quote variable expansions
source "$SCRIPT_DIR/backends/$backend.sh"
[ -f "$TMPFILE" ] && rm -f "$TMPFILE"

# ❌ WRONG: Unquoted variables
source $SCRIPT_DIR/backends/$backend.sh
[ -f $TMPFILE ] && rm -f $TMPFILE
```

### Config Sourcing Pattern

```bash
# ✅ CORRECT: Defaults first, then source config (overrides)
NA_TERMINAL_CMD="alacritty --title always-nvim -e"
NA_PASTE_DELAY="0.2"
NA_FILETYPE="md"

[ -f "$HOME/.config/always-nvim/config" ] && source "$HOME/.config/always-nvim/config"

# ❌ WRONG: Source first, then set defaults (overrides user config)
source "$HOME/.config/always-nvim/config"
NA_TERMINAL_CMD="${NA_TERMINAL_CMD:-alacritty --title always-nvim -e}"
```

### BATS Test Pattern

```bash
# ✅ CORRECT: Test structure
setup() {
    load test_helper
}

@test "Mode A: empty primary selection returns insert mode" {
    backend_get_selection() { printf ''; }
    export -f backend_get_selection
    run detect_mode
    assert_success
    assert_output "A"
}

# ✅ CORRECT: Test naming — "component: scenario description"
@test "clipboard: save and restore preserves exact content" { ... }
@test "cleanup: removes tmpfile on normal exit" { ... }
@test "backend contract: get_selection returns exit 0 on empty" { ... }

# ❌ WRONG: Vague test names
@test "it works" { ... }
@test "test 1" { ... }
```

### Enforcement Guidelines

**All AI agents implementing always-nvim MUST:**

1. Use `backend_` prefix for all backend interface functions — no exceptions
2. Use `NA_` prefix for all config variables
3. Use `printf '%s'` for data output, never `echo` for piped content
4. Use `error_exit()` and `echo_error()` from the shell library — no raw stderr writes
5. Use `check_for_cmd_in_path()` for dependency checks — no manual `command -v`
6. Double-quote all variable expansions
7. Use `local` for all function-scoped variables
8. Follow the 12-step initialization order from the Dependency Chain Analysis
9. Implement Wayland normalization pattern (V1/V2) in `backends/wayland.sh`
10. Name BATS tests as `@test "component: scenario description" { ... }`

## Project Structure & Boundaries

### Complete Project Directory Structure

```
always-nvim/
│
├── always-nvim                          # Main script entry point (~93 lines)
│
├── backends/
│   ├── x11.sh                           # X11 backend: xclip + xdotool (~25 lines)
│   └── wayland.sh                       # Wayland backend: wl-clipboard + wtype + hyprctl (~30 lines)
│
├── config                               # Default config reference file (~10 lines)
│
├── lib/                                 # Shell toolbox library (pruned to project needs)
│   ├── .toolbox                         # Library loader — sources all modules
│   ├── core.sh                          # error_exit, echo_error, echo override, logging
│   ├── file.sh                          # check_for_cmd_in_path, in_path
│   ├── options.sh                       # parse_options framework (post-V1)
│   └── ui.sh                            # ANSI colors, print utilities
│
├── test/
│   ├── test_helper.sh                   # Centralized mock backend functions
│   ├── test_mode_detection.bats         # Mode A/B detection logic
│   ├── test_clipboard.bats              # Save/restore, printf correctness
│   ├── test_cleanup.bats                # Trap, tmpfile, lockfile, backup cleanup
│   └── test_backend_contract.bats       # V1-V4 contract verification
│
└── _bmad-output/                        # BMAD planning artifacts (not shipped)
    ├── product-brief.md
    ├── prd.md
    └── planning-artifacts/
        └── architecture.md
```

### Architectural Boundaries

One architectural boundary: the backend interface.

```
┌─────────────────────────────────────────────────────────┐
│                     always-nvim (main script)            │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ Config       │  │ Mode         │  │ Orchestration  │  │
│  │ (NA_* vars)  │  │ Detection    │  │ (paste flow)   │  │
│  └──────┬───────┘  └──────┬───────┘  └───────┬────────┘  │
│         │                 │                   │           │
│  ═══════╪═════════════════╪═══════════════════╪═══════    │
│         │       BACKEND INTERFACE BOUNDARY    │           │
│         │    (6 functions, ADC-1 + ADC-2)     │           │
│  ═══════╪═════════════════╪═══════════════════╪═══════    │
│         ▼                 ▼                   ▼           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  backend_get_selection()    backend_get_clipboard()  │  │
│  │  backend_set_clipboard()    backend_simulate_paste() │  │
│  │  backend_get_active_window() backend_refocus_window()│  │
│  └─────────────────────────────────────────────────────┘  │
│              │                          │                  │
└──────────────┼──────────────────────────┼──────────────────┘
               ▼                          ▼
    ┌──────────────────┐      ┌──────────────────┐
    │  backends/x11.sh │      │backends/wayland.sh│
    │                  │      │                   │
    │  xclip           │      │  wl-paste/wl-copy │
    │  xdotool         │      │  wtype            │
    │                  │      │  hyprctl + jq     │
    └──────────────────┘      └───────────────────┘
```

**Boundary rule:** The main script NEVER calls `xclip`, `xdotool`, `wl-paste`, `wl-copy`, `wtype`, `hyprctl`, or `jq` directly. All system interaction goes through `backend_*()` functions.

### Requirements to Structure Mapping

| FR Category | Files | Key FRs |
|---|---|---|
| **Mode Detection** (FR1-FR5) | `always-nvim`, `test/test_mode_detection.bats` | Primary selection check, Mode A/B branching |
| **Clipboard Operations** (FR6-FR11) | `always-nvim`, `backends/*.sh`, `test/test_clipboard.bats` | Save, restore, set, printf correctness |
| **Window Management** (FR12-FR15) | `backends/*.sh` | Get active window, refocus, opaque handle |
| **Text Editing** (FR16-FR20) | `always-nvim` | Tmpfile creation, Neovim launch, mode-aware insert, exit code check |
| **Paste Simulation** (FR21-FR23) | `always-nvim`, `backends/*.sh` | Set clipboard, refocus, simulate Ctrl+V, delay |
| **Cleanup** (FR24-FR30) | `always-nvim`, `test/test_cleanup.bats` | Trap, restore clipboard, rm tmpfile, rm lock, clear primary |
| **Backend Abstraction** (FR31-FR35) | `backends/*.sh`, `test/test_backend_contract.bats` | 6-function interface, error contract, Wayland normalization |
| **Configuration** (FR36-FR38) | `config`, `always-nvim` | NA_* variables, config sourcing, defaults |
| **Dependency Checks** (FR3) | `always-nvim` | `check_for_cmd_in_path()` per required tool |

### Cross-Cutting Concerns to Structure Mapping

| Concern | Where It Lives |
|---|---|
| Clipboard safety | Main script (save/restore), cleanup function, backends (V1/V2 normalization) |
| Signal handling | Main script: `trap cleanup EXIT` — wraps everything after clipboard save |
| Error handling | Shell library (`error_exit`, `echo_error`), main script (dependency checks) |
| Backend abstraction | `backends/` directory, sourced at startup, interface enforced by convention |
| Lock file (R3) | Main script: acquire at step 3, release in cleanup |
| Clipboard backup (R1) | Main script: write before overwrite, delete in cleanup |

### Data Flow

```
Invocation:
  hotkey → WM runs always-nvim

Startup:
  source .toolbox → source config → lock file → detect backend → source backend
  → check deps → save clipboard → set trap → cleanup stale files

Mode Detection:
  backend_get_selection() → empty? → Mode A (insert new)
                          → has text? → Mode B (edit selection)

Editing:
  Mode A: mktemp → nvim -c startinsert $TMPFILE
  Mode B: mktemp → write selection to $TMPFILE → nvim $TMPFILE
  (blocks until terminal/nvim exits)

Post-Edit (exit code == 0):
  cat $TMPFILE → printf '%s' | backend_set_clipboard()
  → backend_refocus_window($SOURCE_WINDOW)
  → backend_simulate_paste()
  → sleep $NA_PASTE_DELAY

Post-Edit (exit code != 0):
  skip paste (user aborted)

Cleanup (trap EXIT — always runs):
  printf '%s' "$SAVED_CLIPBOARD" | backend_set_clipboard()  # restore
  rm -f "$TMPFILE"                                           # tmpfile
  rm -f "$LOCK_FILE"                                         # lock
  rm -f "/tmp/always-nvim-clipboard-backup"                  # backup
  [ "$NA_CLEAR_PRIMARY" = "true" ] && clear primary          # ADC-4
```

### Development Workflow

| Action | Command |
|---|---|
| Run | `./always-nvim` (from repo root, or symlink to PATH) |
| Test | `bats test/` |
| Test single file | `bats test/test_clipboard.bats` |
| Config | Edit `~/.config/always-nvim/config` |
| WM rule (i3) | `for_window [title="always-nvim"] floating enable` |
| WM rule (Hyprland) | `windowrulev2 = float,title:always-nvim` |

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
All 7 ADCs, 7 core decisions (D1-D7), 5 risk mitigations (R1-R5), and 5 interface contract findings (V1-V5) are mutually compatible. No contradictions found. Specific compatibility notes:

- ADC-3 (trap-based cleanup) + ADC-4 (configurable primary cleanup) + R1 (clipboard backup) + R5 (exit code check) all converge in the cleanup function without conflict
- ADC-5 (full toolbox loading) enables ADC-6 (echo override safety) — loading everything means the echo override is always present and consistently applied
- ADC-1 (6-function interface) + ADC-2 (error contract) + V1-V4 (contract violations) form a coherent backend specification
- D5 (terminal command template) + D4 (Neovim launch args) compose cleanly: `$NA_TERMINAL_CMD nvim [mode_args] $NA_NVIM_ARGS "$TMPFILE"`

**One coherence issue found and resolved:** The original initialization order (12 steps) had trap setup at step 8 (after clipboard save at step 7), but lock file acquisition at step 3 had no trap protection. If the script failed between steps 3-8, the lock file would be orphaned. **Resolution:** Two-phase trap pattern — minimal `trap 'rm -f "$LOCK_FILE"' EXIT` set immediately at step 5 (lock acquisition), upgraded to full `trap cleanup EXIT` at step 10 (after clipboard save). This ensures lock file cleanup at all stages.

**Pattern Consistency:**
- All naming conventions (NA_* config, backend_* functions, lower_snake_case locals, UPPER_SNAKE_CASE constants) are applied consistently across all sections
- Implementation patterns (printf for data, error_exit for errors, check_for_cmd_in_path for deps) align with the shell library integration
- BATS test patterns follow the "component: scenario description" convention throughout

**Structure Alignment:**
- Project structure supports all decisions: `backends/` directory for ADC-1 polymorphism, `config` file for D1-D7 variables, `test/` with helper for ADC-7
- Single architectural boundary (backend interface) is cleanly expressed in the directory structure
- Integration points (shell library sourcing, config sourcing, backend sourcing) are all file-level `source` operations — structurally simple

### Requirements Coverage Validation ✅

**Functional Requirements Coverage (38/38):**

| FR Category | FRs | Architectural Support |
|---|---|---|
| Mode Detection (FR1-FR5) | 5 | `backend_get_selection()` + mode branching logic in main script |
| Clipboard Operations (FR6-FR11) | 6 | `backend_get_clipboard()`, `backend_set_clipboard()`, save/restore flow, R1 backup, V1-V3 fixes |
| Window Management (FR12-FR15) | 4 | `backend_get_active_window()`, `backend_refocus_window()`, opaque handle pattern |
| Text Editing (FR16-FR20) | 5 | Tmpfile creation, D3 filetype, D4 Neovim args, mode-aware launch, R5 exit code |
| Paste Simulation (FR21-FR23) | 3 | `backend_simulate_paste()`, D6 paste delay, clipboard set before paste |
| Cleanup (FR24-FR30) | 7 | ADC-3 trap, ADC-4 primary clear, R2 stale cleanup, R3 lock cleanup, idempotent cleanup function |
| Backend Abstraction (FR31-FR35) | 5 | ADC-1 interface, ADC-2 error contract, R4 backend override, auto-detection heuristic |
| Configuration (FR36-FR38) | 3 | D1 config location, D7 silent defaults, 6 NA_* variables |
| **Total** | **38** | **All covered** |

**Non-Functional Requirements Coverage (14/14):**

| NFR | Architectural Support |
|---|---|
| <500ms hotkey-to-ready | ADC-5: <5ms library load. 12-step init is all lightweight shell operations. No network, no disk-heavy ops. |
| <300ms exit-to-pasted | D6: configurable paste delay (200ms default). Remaining 100ms for clipboard set + refocus + paste simulation. |
| <50ms clipboard operations | Backend functions are single-command wrappers (xclip/wl-paste). Inherent tool speed. |
| <50MB memory | Bash script + Neovim. No additional runtime. |
| 100% clipboard restoration | ADC-3 trap + R1 backup file. Two layers of protection. |
| 100% temp file cleanup | ADC-3 trap + R2 stale file cleanup. Two layers of protection. |
| No orphan processes | Synchronous execution model. Script blocks on terminal exit. No background processes. |
| 100 consecutive invocations | R3 lock file prevents double-invocation. R2 cleans stale files. Stateless per-invocation design. |
| Backend parity | ADC-2 error contract + V1-V4 normalization. Both backends behave identically to the main script. |
| Alacritty default + configurable | D5: `NA_TERMINAL_CMD` template. |
| Paste into Chromium, Firefox, Slack, GTK/Qt | `backend_simulate_paste()` uses Ctrl+V via xdotool/wtype. Standard paste shortcut. T3 documents Electron edge cases. |
| <300 lines total | Line budget: ~164 lines (~55% of budget). |
| <50 lines per backend | Backend estimate: ~25-30 lines each. |
| New backends require zero main script changes | ADC-1: backends implement 6 functions. Main script calls through interface. |

### Implementation Readiness Validation ✅

**Decision Completeness:**
- All 7 ADCs documented with rationale and trade-offs
- All 7 core decisions (D1-D7) documented with defaults and rationale
- All 5 risk mitigations (R1-R5) documented with line cost estimates
- All 5 interface contract violations (V1-V5) documented with exact fix patterns
- Shell library integration fully mapped (which functions to use, which to defer)

**Structure Completeness:**
- Complete directory tree with every file named and sized
- Boundary diagram showing the single architectural boundary
- FR-to-file mapping for all 38 requirements
- Cross-cutting concern-to-file mapping
- Data flow diagram covering all execution phases

**Pattern Completeness:**
- 8 pattern categories with ✅/❌ examples (naming, functions, error handling, output, scoping, quoting, config, testing)
- 10 enforcement rules as explicit checklist for implementing agents
- Wayland normalization pattern (V1/V2) shown with exact code
- BATS test structure pattern with naming convention

### Gap Analysis Results

**Critical Gaps:** None found.

**Important Gaps (resolved during validation):**

| # | Gap | Resolution |
|---|---|---|
| G1 | Two-phase trap pattern not reflected in init order | Updated initialization order from 12 to 14 steps. Minimal trap at step 5 (lock acquisition), full trap at step 10 (after clipboard save). |
| G2 | `SCRIPT_DIR` needs symlink-safe resolution | Added `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` as step 1 of initialization order. |
| G3 | Shellcheck directives not specified | **Promoted to V1 scope.** All script files must include appropriate `# shellcheck` directives (e.g., `# shellcheck shell=bash`, source directives for sourced files). |
| G4 | No `--help` / `--version` flags | **Promoted to V1 scope.** Simple `case "$1"` at step 3 of initialization order handles `--help` and `--version`. Full `parse_options()` integration remains post-V1. |

**Nice-to-Have Gaps:** None identified. Architecture is lean and complete for V1 scope.

### Validation Issues Addressed

**Two-Phase Trap (Critical — resolved):**
The original 12-step initialization order had a gap: lock file acquired at step 3 but trap not set until step 8. A crash between steps 3-8 would orphan the lock file, preventing future invocations. Resolved by splitting trap setup into two phases: minimal trap immediately after lock acquisition (step 5), upgraded to full cleanup trap after clipboard save (step 10).

**Shellcheck Directives (Important — promoted to V1):**
Originally not in scope. Maestro requested promotion to V1. All shell script files (`always-nvim`, `backends/x11.sh`, `backends/wayland.sh`, `test/test_helper.sh`) must include shellcheck directives for static analysis compatibility.

**Help/Version Flags (Important — promoted to V1):**
Originally deferred to post-V1 with full `parse_options()`. Maestro requested lightweight `--help` and `--version` support. Implemented as simple `case "$1"` pattern at initialization step 3, before any system state changes. Adds ~5 lines to the main script.

### Updated Initialization Order (14 Steps)

| Step | Operation | Depends On | Critical Ordering |
|---|---|---|---|
| 1 | `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` | Nothing | Must be first — all paths derived from this |
| 2 | `source "$SHELLTOOLSPATH"/lib/.toolbox` | `$SHELLTOOLSPATH` set | After step 1 — library functions needed below |
| 3 | Handle `--help` / `--version` | Nothing | Before any system state changes |
| 4 | Parse config / env vars (defaults + source XDG config) | Library loaded (`error_exit()`) | After step 2 |
| 5 | Acquire lock file (R3) + set minimal trap | Nothing | **Before any system state changes** — earliest after config |
| 6 | Detect backend (env vars + NA_BACKEND override) | Config parsed | After step 4 |
| 7 | Source backend file | Backend detected | After step 6 — functions undefined otherwise |
| 8 | Check dependencies | Backend sourced (to know which tools) | **After step 7** — otherwise don't know what to check |
| 9 | Save clipboard + clipboard backup (R1) | Dependencies verified, backend available | **After step 8** — `backend_get_clipboard()` requires tools |
| 10 | Upgrade trap to full cleanup | Clipboard saved | **After step 9** — cleanup must not restore unsaved state (ADC-3) |
| 11 | Stale file cleanup (R2) | mktemp prefix pattern | Non-critical ordering |
| 12 | Determine mode (A/B) | Backend functions available | After step 7 |
| 13 | Create tmpfile + pre-fill (Mode B) | Mode determined | After step 12 |
| 14 | Launch terminal + nvim | Everything above | Last step — blocks until exit |

**Critical constraints:**
- Step 5 sets minimal trap (`rm -f "$LOCK_FILE"`) immediately after lock acquisition
- Step 10 MUST come after step 9 (ADC-3: full trap after clipboard save)
- Step 8 MUST come after step 7 (need backend to know which tools to check)
- Step 5 MUST come before step 14 (lock before any long-running operation)

### Updated Line Budget

| Component | Estimated Lines | Notes |
|---|---|---|
| SCRIPT_DIR + library sourcing | ~5 | Symlink-safe dir resolution + source .toolbox |
| Help/version handling | ~8 | `case "$1"` for --help, --version |
| Config parsing (defaults + source) | ~8 | NA_* defaults, conditional source |
| Lock file (R3) + minimal trap | ~7 | Check/create PID lock, set minimal trap |
| Backend detection + sourcing | ~10 | Env var checks, source backend file |
| Dependency checks | ~10 | `check_for_cmd_in_path` per tool |
| Clipboard save + backup (R1) + trap upgrade | ~10 | Save clipboard, write backup, upgrade EXIT trap |
| Mode detection + tmpfile | ~10 | Check primary selection, create/pre-fill tmpfile |
| Terminal launch + wait | ~5 | Launch Alacritty with nvim, wait |
| Exit code check + paste flow | ~15 | R5 check, read tmpfile, set clipboard, refocus, paste |
| Cleanup function | ~15 | Restore clipboard, rm tmpfile, rm lock, rm backup, clear primary |
| Stale file cleanup (R2) | ~2 | find + delete old tmpfiles |
| Shellcheck directives | ~3 | Header directives per file |
| **Main script total** | **~108** | Well under 300-line budget |
| Backend file (each) | ~27 | 6 functions + header/contract/shellcheck |
| Config file | ~10 | Default env var values |
| **Grand total** | **~172** | ~57% of budget used |

### Architecture Completeness Checklist

**✅ Requirements Analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**✅ Architectural Decisions**

- [x] Critical decisions documented (ADC-1 through ADC-7, D1-D7)
- [x] Technology stack fully specified (Bash, shell library, BATS)
- [x] Integration patterns defined (backend interface, config sourcing, library loading)
- [x] Performance considerations addressed (<500ms, <300ms, <50ms targets)

**✅ Implementation Patterns**

- [x] Naming conventions established (NA_*, backend_*, snake_case, UPPER_SNAKE)
- [x] Structure patterns defined (project tree, boundary diagram)
- [x] Communication patterns specified (printf for data, error_exit for errors)
- [x] Process patterns documented (config sourcing, Wayland normalization, cleanup)

**✅ Project Structure**

- [x] Complete directory structure defined
- [x] Component boundaries established (single backend interface boundary)
- [x] Integration points mapped (3 source operations)
- [x] Requirements to structure mapping complete (38 FRs → files)

**✅ Risk Management**

- [x] All risks identified and mitigated (R1-R5, ~17 lines)
- [x] Interface contract violations documented and fixed (V1-V5)
- [x] Constraint tensions identified and resolved (T1-T4)
- [x] Two-phase trap pattern prevents orphaned lock files

**✅ Testing Strategy**

- [x] Framework selected (BATS with extensions)
- [x] Test structure defined (4 test files + helper)
- [x] Mock strategy documented (ADC-7, centralized helper)
- [x] Test-first targets identified (V1-V3 contract violations)

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

The architecture is lean (~172 lines, 57% of budget), well-specified (14-step initialization order, 6-function backend interface, 10 enforcement rules), and thoroughly validated (38/38 FRs, 14/14 NFRs, 0 critical gaps remaining).

**Key Strengths:**
- Single architectural boundary keeps complexity minimal
- Two-phase trap pattern provides robust cleanup at all execution stages
- Backend error contract (ADC-2) + Wayland normalization (V1-V4) ensures cross-platform parity
- Line budget has 43% headroom for future enhancements
- Shell library integration eliminates boilerplate (~40% of common patterns handled by library)

**Areas for Future Enhancement:**
- `parse_options()` integration for full CLI option support (T1)
- `$SHELLTOOLSPATH` auto-detection for portability (T4)
- Per-invocation `--filetype` override (D3 extension)
- Integration tests against real backends (post-V1)
- Additional backends (e.g., Sway, GNOME Wayland)

### Implementation Handoff

**AI Agent Guidelines:**

- Follow all architectural decisions exactly as documented (ADC-1 through ADC-7, D1-D7)
- Use implementation patterns consistently across all components (10 enforcement rules)
- Respect project structure and the single backend interface boundary
- Implement the 14-step initialization order precisely — misordering causes bugs
- Apply Wayland normalization pattern (V1/V2) in `backends/wayland.sh`
- Include shellcheck directives in all script files (G3)
- Implement `--help` / `--version` via `case "$1"` at step 3 (G4)
- Use `printf '%s'` for all data output — never `echo` for piped content
- Refer to this document for all architectural questions

**First Implementation Priority:**
1. Create `backends/x11.sh` and `backends/wayland.sh` with the 6-function interface + contract violations fixed (V1-V4)
2. Create `test/test_helper.sh` with centralized mock functions
3. Write `test/test_backend_contract.bats` — test-first for V1-V3 contract violations (P3)
4. Implement main script following the 14-step initialization order
5. Write remaining test files
