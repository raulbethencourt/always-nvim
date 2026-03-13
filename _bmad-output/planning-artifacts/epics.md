---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
  - restructure-critical-fixes
inputDocuments:
  - "_bmad-output/prd.md"
  - "_bmad-output/planning-artifacts/architecture.md"
restructureReason: "Implementation readiness report flagged 2 critical violations: Epic 1 had no user value (pure scaffolding), Epic 5 was a technical epic (test suite). Merged old Epic 1 into Epic 1 (Core Editing Loop) so first epic delivers a working tool. Distributed Epic 5 test stories into the epics they verify. Old Epic 3 → Epic 2, old Epic 4 → Epic 3."
---

# always-nvim - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for always-nvim, decomposing the requirements from the PRD and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: The script can detect whether the current session is X11 or Wayland via `$WAYLAND_DISPLAY` environment variable
FR2: The script can source the correct backend module (`x11.sh` or `wayland.sh`) based on detected display server
FR3: The script can fail cleanly with a descriptive error if required backend dependencies are not installed
FR4: The script can save the current system clipboard contents to a variable before any operations
FR5: The script can restore previously saved clipboard contents after all operations complete
FR6: The script can restore clipboard contents on abort (`:q!` with empty/unchanged file)
FR7: The script can restore clipboard contents on signal interruption (SIGINT, SIGTERM)
FR8: The script can copy arbitrary text content to the system clipboard
FR9: The script can read the current primary selection (X11 primary / Wayland primary)
FR10: The script can determine Mode A (insert new) when primary selection is empty
FR11: The script can determine Mode B (edit selection) when primary selection contains text
FR12: The script can create a unique temporary file in the configured temp directory
FR13: The script can write captured selection text to the temp file (Mode B)
FR14: The script can read the temp file contents after Neovim exits
FR15: The script can detect abort conditions (temp file empty or unchanged from original)
FR16: The script can delete the temp file on all exit paths (success, abort, error, signal)
FR17: The script can spawn a configured terminal emulator with a specific window title (`always-nvim`)
FR18: The script can launch Neovim inside the terminal with the temp file and configured filetype
FR19: The script can pass additional Neovim arguments from configuration
FR20: The script can block execution until the terminal process exits
FR21: The script can record the currently focused window identifier before spawning the terminal
FR22: The script can refocus the previously recorded window after Neovim exits
FR23: The script can wait a configurable delay after refocus before simulating paste
FR24: The script can simulate a Ctrl+V keystroke in the focused application
FR25: The script can wait a configurable delay after paste before restoring the clipboard
FR26: The script can load a shell-sourceable config file from `~/.config/always-nvim/config` if it exists
FR27: The script can operate with sensible defaults when no config file is present
FR28: Users can configure: terminal emulator, title flag, dimensions, filetype, nvim args, paste delay, focus delay, temp directory
FR29: The install script can copy all script files to a user-accessible location
FR30: The install script can create the `~/.config/always-nvim/` directory and example config
FR31: The install script can display WM hotkey configuration snippets for i3 and Hyprland
FR32: Each backend implements `backend_get_selection()` to return currently selected text
FR33: Each backend implements `backend_set_clipboard()` to set clipboard from stdin (consolidated from original FR33+FR35)
FR34: Each backend implements `backend_get_clipboard()` to return current clipboard contents
FR35: Each backend implements `backend_simulate_paste()` to simulate Ctrl+V keystroke
FR36: Each backend implements `backend_get_active_window()` to return focused window identifier
FR37: Each backend implements `backend_refocus_window()` to refocus a previously saved window
FR38: The script can handle `--help` and `--version` flags before any system state changes

### NonFunctional Requirements

NFR1: Hotkey press to Neovim cursor ready shall complete in under 500ms as perceived by the user during normal desktop usage
NFR2: Neovim exit to text pasted in source application shall complete in under 300ms as perceived by the user
NFR3: Clipboard save and restore operations shall add no perceptible latency (<50ms each)
NFR4: The complete script (excluding Neovim editing time) shall consume less than 50MB of memory
NFR5: Clipboard contents shall be restored to pre-invocation state on 100% of invocations, measured across success, abort, error, and signal-interrupted paths
NFR6: Temp files shall be cleaned up on 100% of invocations, including signal-interrupted paths, measured by checking `/tmp/always-nvim-*` after each invocation
NFR7: The script shall not leave orphan processes after any exit path
NFR8: The tool shall function correctly after 100 consecutive invocations without system restart
NFR9: X11 backend shall function identically to Wayland backend from the user's perspective, verified by running the same test scenarios on both Regolith (i3/X11) and Omarchy (Hyprland/Wayland)
NFR10: The tool shall work with Alacritty as the default terminal and support configuration for alternative terminals that accept a `--title` equivalent flag
NFR11: The tool shall paste correctly into Chromium-based browsers, Firefox, Slack (Electron), and standard GTK/Qt text inputs
NFR12: Total codebase shall remain under 300 lines of Bash (excluding comments and blank lines)
NFR13: Each backend module shall remain under 50 lines of Bash
NFR14: Adding a new display-server backend shall require only creating a new file implementing the 6-function interface contract, with no changes to the main script

### Additional Requirements

**From Architecture — Structural/Technical:**
- Custom from scratch (no starter template) — architecture defines exact file structure and function signatures
- Shell library integration: source full `.toolbox` at startup (ADC-5), use `error_exit()`, `echo_error()`, `check_for_cmd_in_path()` from library
- Backend interface consolidated to 6 functions (ADC-1): `backend_get_selection()`, `backend_get_clipboard()`, `backend_set_clipboard()`, `backend_simulate_paste()`, `backend_get_active_window()`, `backend_refocus_window()`
- Backend error contract (ADC-2): success = stdout + exit 0, failure = exit 1 + stderr, empty result = empty stdout + exit 0
- Trap-based cleanup architecture (ADC-3): two-phase trap — minimal trap after lock acquisition, full cleanup trap after clipboard save
- Configurable primary selection cleanup (ADC-4): `NA_CLEAR_PRIMARY` (default: true)
- Echo override verified safe (ADC-6): shell library's `echo()` override does not interfere with backend stdout data flow
- Backend test strategy (ADC-7): inline mocks via centralized `test/test_helper.sh`

**From Architecture — Risk Mitigations (all required for V1):**
- R1: Persistent clipboard backup file (`/tmp/always-nvim-clipboard-backup`) before overwriting clipboard (~3 lines)
- R2: Stale temp file cleanup on startup using `find /tmp/always-nvim-* -mmin +60 -delete` (~2 lines)
- R3: PID lock file at `/tmp/always-nvim.lock` to prevent double invocation (~5 lines)
- R4: Backend override config `NA_BACKEND=x11|wayland` + improved detection heuristic (check `$WAYLAND_DISPLAY`, `$XDG_SESSION_TYPE`, `$DISPLAY`) (~5 lines)
- R5: Check Neovim exit code — `:cq` (non-zero) skips paste, `:wq` (zero) proceeds (~2 lines)

**From Architecture — Interface Contract Violations (must be fixed in implementation):**
- V1: Wayland `backend_get_selection()` must normalize `wl-paste --primary` exit 1 on empty selection to exit 0
- V2: Wayland `backend_get_clipboard()` must normalize `wl-paste` exit 1 on empty clipboard to exit 0
- V3: All clipboard pipe operations must use `printf '%s'` instead of `echo` to prevent trailing newline corruption
- V4: Wayland `backend_get_active_window()` must check for `"0x0"` or `"null"` from `hyprctl` and return exit 1

**From Architecture — Validation Gaps (promoted to V1):**
- G3: All script files must include shellcheck directives (`# shellcheck shell=bash`, source directives)
- G4: Lightweight `--help` / `--version` via `case "$1"` at initialization step 3

**From Architecture — 14-Step Initialization Order (critical — misordering causes bugs):**
1. `SCRIPT_DIR` resolution (symlink-safe)
2. Source `.toolbox` library
3. Handle `--help` / `--version`
4. Parse config / env vars (defaults + source XDG config)
5. Acquire lock file + set minimal trap
6. Detect backend
7. Source backend file
8. Check dependencies
9. Save clipboard + clipboard backup
10. Upgrade trap to full cleanup
11. Stale file cleanup
12. Determine mode (A/B)
13. Create tmpfile + pre-fill (Mode B)
14. Launch terminal + Neovim

### FR Coverage Map

| FR | Epic | Description |
|----|------|-------------|
| FR1 | Epic 1 | Backend detection (X11/Wayland) |
| FR2 | Epic 1 | Source correct backend module |
| FR3 | Epic 1 | Fail cleanly on missing dependencies |
| FR4 | Epic 1 | Save clipboard before operations |
| FR5 | Epic 1 | Restore clipboard after operations |
| FR6 | Epic 2 | Restore clipboard on abort |
| FR7 | Epic 2 | Restore clipboard on signal interruption |
| FR8 | Epic 1 | Copy text to system clipboard |
| FR9 | Epic 1 | Read primary selection |
| FR10 | Epic 1 | Determine Mode A (insert new) |
| FR11 | Epic 1 | Determine Mode B (edit selection) |
| FR12 | Epic 1 | Create unique temp file |
| FR13 | Epic 1 | Write selection to temp file (Mode B) |
| FR14 | Epic 1 | Read temp file after Neovim exits |
| FR15 | Epic 2 | Detect abort conditions |
| FR16 | Epic 2 | Delete temp file on all exit paths |
| FR17 | Epic 1 | Spawn terminal with window title |
| FR18 | Epic 1 | Launch Neovim with temp file and filetype |
| FR19 | Epic 1 | Pass additional Neovim arguments |
| FR20 | Epic 1 | Block until terminal exits |
| FR21 | Epic 1 | Record active window before spawn |
| FR22 | Epic 1 | Refocus window after Neovim exits |
| FR23 | Epic 1 | Configurable delay after refocus |
| FR24 | Epic 1 | Simulate Ctrl+V paste |
| FR25 | Epic 1 | Configurable delay after paste |
| FR26 | Epic 1 | Load shell-sourceable config |
| FR27 | Epic 1 | Operate with sensible defaults |
| FR28 | Epic 1 | All options configurable |
| FR29 | Epic 3 | Install script copies files |
| FR30 | Epic 3 | Install script creates config directory |
| FR31 | Epic 3 | Install script shows WM snippets |
| FR32 | Epic 1 | `backend_get_selection()` |
| FR33 | Epic 1 | `backend_set_clipboard()` |
| FR34 | Epic 1 | `backend_get_clipboard()` |
| FR35 | Epic 1 | `backend_simulate_paste()` |
| FR36 | Epic 1 | `backend_get_active_window()` |
| FR37 | Epic 1 | `backend_refocus_window()` |
| FR38 | Epic 1 | Handle `--help` / `--version` flags |
| FR28 | Epic 4 | Configurable NVIM_APPNAME for dedicated Neovim config directory |

## Epic List

### Epic 1: Core Editing Loop
The user can press a hotkey, edit text in a floating Neovim window (insert new or edit selected), and have the result pasted back into the source application — the complete end-to-end flow including backend abstraction, configuration, and test coverage.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR8, FR9, FR10, FR11, FR12, FR13, FR14, FR17, FR18, FR19, FR20, FR21, FR22, FR23, FR24, FR25, FR26, FR27, FR28, FR32, FR33, FR34, FR35, FR36, FR37, FR38
**NFRs addressed:** NFR1, NFR2, NFR3, NFR4, NFR9, NFR10, NFR11, NFR12, NFR13, NFR14

### Epic 2: Zero Side Effects — Safety, Cleanup & Abort Handling
The tool guarantees zero side effects on every exit path — clipboard is always restored, temp files are always cleaned up, double invocation is prevented, and aborts leave no trace.
**FRs covered:** FR6, FR7, FR15, FR16
**NFRs addressed:** NFR5, NFR6, NFR7, NFR8

### Epic 3: Installation & Distribution
The user can install always-nvim on a new machine with a single script that copies files, creates config, and shows WM-specific hotkey setup instructions for both i3 and Hyprland.
**FRs covered:** FR29, FR30, FR31

### Epic 4: Enhanced Neovim Configuration
The user can configure always-nvim to use a dedicated Neovim config directory via the `NVIM_APPNAME` environment variable, enabling fast startup with a minimal config separate from their main Neovim setup.
**FRs covered:** FR28 (extended)
**NFRs addressed:** NFR1, NFR12

## Epic 1: Core Editing Loop

The user can press a hotkey, edit text in a floating Neovim window (insert new or edit selected), and have the result pasted back into the source application — the complete end-to-end flow including backend abstraction, configuration, and test coverage.

### Story 1.1: Project Structure, Configuration & Backend Detection

As a user,
I want the project scaffolded with a main script that loads the shell library, parses configuration with sensible defaults, handles `--help`/`--version` flags, and detects the correct display-server backend,
So that the tool has a fully configured environment and correct backend before any system interactions begin.

**Acceptance Criteria:**

**Given** the project has no existing source files
**When** this story is implemented
**Then** the following file structure exists:
- `always-nvim` (main script with shebang, shellcheck directives, `SCRIPT_DIR` resolution)
- `backends/x11.sh` (empty scaffold with shellcheck directives and contract comment header)
- `backends/wayland.sh` (empty scaffold with shellcheck directives and contract comment header)
- `config` (default config reference with all `NA_*` variables)

**Given** `$SHELLTOOLSPATH` is set in the environment
**When** the script starts
**Then** it resolves `SCRIPT_DIR` via symlink-safe `$(cd "$(dirname "$0")" && pwd)` and sources `"$SHELLTOOLSPATH"/lib/.toolbox` (ADC-5, init steps 1-2)

**Given** `$SHELLTOOLSPATH` is not set
**When** the script starts
**Then** it exits with a descriptive error message

**Given** no config file exists at `~/.config/always-nvim/config`
**When** config parsing runs
**Then** all `NA_*` variables are set to their defaults: `NA_TERMINAL_CMD="alacritty --title always-nvim -e"`, `NA_BACKEND=auto`, `NA_CLEAR_PRIMARY="true"`, `NA_FILETYPE="md"`, `NA_NVIM_ARGS=""`, `NA_PASTE_DELAY="0.2"` (FR27, D7)

**Given** a config file exists at `~/.config/always-nvim/config`
**When** config parsing runs
**Then** defaults are set first, then the config file is sourced, allowing user values to override defaults (FR26, FR28)

**Given** the user runs `always-nvim --help`
**When** the script processes arguments at init step 3
**Then** it prints usage information and exits before any system state changes (FR38, G4)

**Given** the user runs `always-nvim --version`
**When** the script processes arguments at init step 3
**Then** it prints the version string and exits before any system state changes (FR38, G4)

**Given** the script runs on an X11 session where `$WAYLAND_DISPLAY` is unset
**When** backend detection executes
**Then** the script sources `backends/x11.sh` (FR1, FR2)

**Given** the script runs on a Wayland session where `$WAYLAND_DISPLAY` is set
**When** backend detection executes
**Then** the script sources `backends/wayland.sh` (FR1, FR2)

**Given** the user has set `NA_BACKEND=x11` or `NA_BACKEND=wayland` in config
**When** backend detection executes
**Then** the config override takes precedence over environment variable detection (R4)

**Given** the backend detection uses the improved heuristic
**When** `$WAYLAND_DISPLAY` is unset
**Then** it falls back to checking `$XDG_SESSION_TYPE`, then `$DISPLAY` (R4)

**And** init steps 1-8 execute in exact order per the 14-step initialization sequence
**And** the script includes `# shellcheck shell=bash` directive (G3)
**And** all config variables use the `NA_` prefix
**And** defaults are set before sourcing config (not the `${VAR:-default}` anti-pattern)

### Story 1.2: X11 Backend Implementation

As a developer,
I want the X11 backend to implement all 6 interface functions using xdotool and xclip,
So that the main script can interact with the X11 display server through a clean abstraction.

**Acceptance Criteria:**

**Given** the X11 backend is sourced
**When** `backend_get_selection()` is called with text in the primary selection
**Then** it returns the selected text on stdout with exit code 0

**Given** the X11 backend is sourced
**When** `backend_get_selection()` is called with no primary selection
**Then** it returns empty stdout with exit code 0

**Given** the X11 backend is sourced
**When** `backend_get_clipboard()` is called
**Then** it returns current clipboard contents on stdout with exit code 0

**Given** the X11 backend is sourced
**When** content is piped to `backend_set_clipboard()`
**Then** the system clipboard contains the exact content with no trailing newline added (V3: uses `printf '%s'` pattern)

**Given** the X11 backend is sourced
**When** `backend_simulate_paste()` is called
**Then** it simulates a Ctrl+V keystroke via xdotool

**Given** the X11 backend is sourced
**When** `backend_get_active_window()` is called
**Then** it returns an opaque window handle on stdout with exit code 0

**Given** the X11 backend is sourced and a window handle was previously obtained
**When** `backend_refocus_window()` is called with that handle
**Then** the specified window regains focus

**Given** required X11 tools (xclip, xdotool) are not installed
**When** dependency checking runs via `check_for_cmd_in_path()`
**Then** the script calls `error_exit()` with a descriptive message naming the missing tool (FR3)

**And** the backend file is under 50 lines of Bash excluding comments (NFR13)
**And** the file includes `# shellcheck shell=bash` directive (G3)
**And** all functions use the `backend_` prefix (ADC-1)
**And** all functions follow the error contract: success = stdout + exit 0, failure = exit 1 + stderr (ADC-2)

### Story 1.3: Wayland Backend Implementation

As a developer,
I want the Wayland/Hyprland backend to implement all 6 interface functions using wl-clipboard, wtype, hyprctl, and jq with proper normalization,
So that the main script can interact with the Wayland display server identically to X11.

**Acceptance Criteria:**

**Given** the Wayland backend is sourced
**When** `backend_get_selection()` is called with text in the primary selection
**Then** it returns the selected text on stdout with exit code 0

**Given** the Wayland backend is sourced
**When** `backend_get_selection()` is called with no primary selection
**Then** it returns empty stdout with exit code 0 (V1: normalizes `wl-paste --primary` exit 1 via `result=$(wl-paste --primary 2>/dev/null) || true; printf '%s' "$result"`)

**Given** the Wayland backend is sourced
**When** `backend_get_clipboard()` is called with an empty clipboard
**Then** it returns empty stdout with exit code 0 (V2: same normalization pattern as V1)

**Given** the Wayland backend is sourced
**When** content is piped to `backend_set_clipboard()`
**Then** the system clipboard contains the exact content with no trailing newline added (V3)

**Given** the Wayland backend is sourced
**When** `backend_simulate_paste()` is called
**Then** it simulates a Ctrl+V keystroke via wtype

**Given** the Wayland backend is sourced
**When** `backend_get_active_window()` is called and a window is focused
**Then** it returns an opaque window handle from `hyprctl activewindow -j` via jq with exit code 0

**Given** the Wayland backend is sourced
**When** `backend_get_active_window()` is called and `hyprctl` returns `"0x0"` or address is `"null"`
**Then** it returns exit code 1 (V4)

**Given** the Wayland backend is sourced and a window handle was previously obtained
**When** `backend_refocus_window()` is called with that handle
**Then** `hyprctl dispatch` is used to refocus the window

**Given** required Wayland tools (wl-paste, wl-copy, wtype, hyprctl, jq) are not installed
**When** dependency checking runs via `check_for_cmd_in_path()`
**Then** the script calls `error_exit()` with a descriptive message naming the missing tool (FR3)

**And** the backend file is under 50 lines of Bash excluding comments (NFR13)
**And** the file includes `# shellcheck shell=bash` directive (G3)
**And** all functions use the `backend_` prefix (ADC-1)
**And** all functions follow the error contract (ADC-2)
**And** both backends produce identical behavior from the caller's perspective (NFR9)

### Story 1.4: Mode Detection & Temp File Preparation

As a user,
I want the tool to automatically detect whether I have text selected (edit mode) or not (insert mode) and prepare the editing environment accordingly,
So that I get the right behavior without any manual mode switching.

**Acceptance Criteria:**

**Given** no text is currently selected (primary selection is empty)
**When** mode detection runs via `backend_get_selection()`
**Then** Mode A (insert new) is determined and an empty temp file is created via `mktemp /tmp/always-nvim-XXXXXX.$NA_FILETYPE` (FR9, FR10, FR12)

**Given** text is currently selected (primary selection contains content)
**When** mode detection runs via `backend_get_selection()`
**Then** Mode B (edit selection) is determined, a temp file is created, and the selection is written to it using `printf '%s'` (FR9, FR11, FR12, FR13)

**Given** Mode A is detected
**When** Neovim launch arguments are assembled
**Then** `-c "startinsert"` is included so the user starts typing immediately (D4)

**Given** Mode B is detected
**When** Neovim launch arguments are assembled
**Then** Neovim opens in normal mode with the selected text loaded (D4)

**Given** the user has set `NA_NVIM_ARGS` in config
**When** Neovim launch arguments are assembled
**Then** the user's additional arguments are appended (FR19)

**And** the temp file uses the configured `NA_FILETYPE` as its extension (D3)
**And** all content written to temp file uses `printf '%s'` — never `echo` (V3)
**And** this corresponds to init steps 12-13 in the initialization order

### Story 1.5: Terminal Spawn & Neovim Orchestration

As a user,
I want a floating Neovim terminal to appear when I press the hotkey and the script to wait until I'm done editing,
So that I can edit text with full Neovim capabilities in a distraction-free floating window.

**Acceptance Criteria:**

**Given** mode detection and temp file creation are complete
**When** the terminal is launched
**Then** `$NA_TERMINAL_CMD` is executed with Neovim, the mode-aware arguments, any `$NA_NVIM_ARGS`, and the temp file path (FR17, FR18, FR19, D5)

**Given** the terminal window title is set to `always-nvim`
**When** the window manager processes the window
**Then** configured floating/sizing rules match on the title string (FR17)

**Given** the terminal has been spawned
**When** the script continues execution
**Then** it blocks (waits synchronously) until the terminal process exits (FR20)

**Given** Neovim is running inside the terminal
**When** the user types `:wq` or `:q!` or `:cq`
**Then** Neovim exits, the terminal closes, and the script unblocks with Neovim's exit code available

**And** this corresponds to init step 14 in the initialization order
**And** the tool achieves <500ms from hotkey press to Neovim cursor ready (NFR1)
**And** no background processes are spawned — fully synchronous execution (NFR7)

### Story 1.6: Paste Flow & Clipboard Restoration

As a user,
I want my edited text to appear in the source application after I save and close Neovim, with my original clipboard contents preserved,
So that the editing result lands where I need it without disrupting my clipboard.

**Acceptance Criteria:**

**Given** the script starts and backends are available
**When** the active window is recorded before terminal spawn
**Then** `backend_get_active_window()` saves the source window handle to a variable (FR21)

**Given** the script starts and backends are available
**When** clipboard save runs at init step 9
**Then** `backend_get_clipboard()` saves the current clipboard contents to `SAVED_CLIPBOARD` (FR4)

**Given** Neovim exits with exit code 0 (`:wq`) and the temp file has content
**When** the paste flow executes
**Then** the temp file contents are read, set to clipboard via `printf '%s' "$content" | backend_set_clipboard()`, the source window is refocused via `backend_refocus_window()`, then `backend_simulate_paste()` simulates Ctrl+V (FR8, FR14, FR22, FR24)

**Given** paste simulation has been sent
**When** `$NA_PASTE_DELAY` seconds have elapsed
**Then** the original clipboard is restored via `printf '%s' "$SAVED_CLIPBOARD" | backend_set_clipboard()` (FR5, FR25, D6)

**Given** a configurable focus delay is set
**When** the source window is refocused
**Then** the script waits `$NA_FOCUS_DELAY` seconds before simulating paste (FR23)

**And** the exit-to-text-pasted latency is under 300ms (NFR2)
**And** clipboard save/restore adds no perceptible latency (<50ms each) (NFR3)
**And** the tool pastes correctly into Chromium, Firefox, Slack, GTK/Qt inputs (NFR11)
**And** all clipboard pipe operations use `printf '%s'` — never `echo` (V3)

### Story 1.7: Test Helper, Backend Contract & Mode Detection Tests

As a developer,
I want a centralized test helper with mock backend functions and BATS tests that verify the 6-function interface contract, Wayland normalization fixes, and Mode A/B detection logic,
So that backend parity is verified, contract violations V1-V4 have regression coverage, and mode detection regressions are caught.

**Acceptance Criteria:**

**Given** the test infrastructure is being set up
**When** `test/test_helper.sh` is created
**Then** it provides mock implementations for all 6 `backend_*` functions that tests can override per-scenario (ADC-7)

**Given** `test/test_backend_contract.bats` exists
**When** `bats test/test_backend_contract.bats` runs
**Then** it verifies: `backend_get_selection()` returns exit 0 + empty stdout when no selection exists — for both backends (V1 regression)

**Given** the backend contract tests run
**When** testing clipboard operations
**Then** it verifies: `backend_get_clipboard()` returns exit 0 + empty stdout when clipboard is empty — for both backends (V2 regression)

**Given** the backend contract tests run
**When** testing clipboard data integrity
**Then** it verifies: `backend_set_clipboard()` preserves exact content without trailing newline addition (V3 regression)

**Given** the backend contract tests run
**When** testing Wayland active window edge case
**Then** it verifies: `backend_get_active_window()` returns exit 1 when `hyprctl` reports null/zero address (V4 regression)

**Given** `test/test_mode_detection.bats` exists
**When** testing with empty primary selection (mocked)
**Then** mode detection returns Mode A (insert new) (FR10)

**Given** the mode detection tests run
**When** testing with non-empty primary selection (mocked)
**Then** mode detection returns Mode B (edit selection) and the selection content is captured (FR11)

**Given** the mode detection tests run
**When** testing temp file creation in Mode A
**Then** an empty temp file is created with the configured `$NA_FILETYPE` extension (FR12)

**Given** the mode detection tests run
**When** testing temp file creation in Mode B
**Then** the temp file is created and pre-filled with the selection content using `printf '%s'` (FR13)

**Given** `test/test_clipboard.bats` exists
**When** testing the save/restore cycle
**Then** it verifies clipboard contents are identical before and after a simulated invocation (FR4, FR5)

**Given** the clipboard tests run
**When** testing content with special characters (newlines, tabs, unicode, empty string)
**Then** `printf '%s'` preserves exact content through the save → overwrite → restore cycle (V3)

**Given** the clipboard tests run
**When** testing the backup file mechanism
**Then** it verifies `/tmp/always-nvim-clipboard-backup` is created before clipboard overwrite and deleted on normal cleanup (R1)

**And** all tests follow naming convention: `@test "backend contract: scenario description" { ... }` or `@test "mode detection: scenario description" { ... }` or `@test "clipboard: scenario description" { ... }` (Architecture pattern)
**And** test files include `setup()` that loads `test_helper`
**And** mock functions are sourced from `test/test_helper.sh`

## Epic 2: Zero Side Effects — Safety, Cleanup & Abort Handling

The tool guarantees zero side effects on every exit path — clipboard is always restored, temp files are always cleaned up, double invocation is prevented, and aborts leave no trace.

### Story 2.1: Two-Phase Trap & Cleanup System

As a user,
I want the tool to always restore my clipboard and clean up temp files regardless of how the script exits — normal, abort, error, or signal kill,
So that using the tool never corrupts my clipboard or leaves garbage in /tmp.

**Acceptance Criteria:**

**Given** the script has acquired a lock file at init step 5
**When** the minimal trap is set
**Then** `trap 'rm -f "$LOCK_FILE"' EXIT` is registered immediately, ensuring the lock file is cleaned up even if the script fails between steps 5-9 (ADC-3 two-phase)

**Given** the clipboard has been saved at init step 9
**When** the full cleanup trap is set at init step 10
**Then** the EXIT trap is upgraded to call a full `cleanup()` function that: restores clipboard via `printf '%s' "$SAVED_CLIPBOARD" | backend_set_clipboard()`, removes `$TMPFILE`, removes `$LOCK_FILE`, removes `/tmp/always-nvim-clipboard-backup`, and optionally clears primary selection if `$NA_CLEAR_PRIMARY="true"` (FR5, FR6, FR7, FR16, ADC-4)

**Given** the cleanup function is called
**When** it executes
**Then** it is idempotent — safe to call multiple times, checks if `$SAVED_CLIPBOARD` is set and `$TMPFILE` exists before acting

**Given** the script receives SIGINT (Ctrl+C) or SIGTERM during any phase after trap upgrade
**When** the EXIT trap fires
**Then** the full cleanup function executes, restoring clipboard and removing all temp files (FR7)

**Given** the clipboard is about to be overwritten with edited content for paste
**When** the clipboard backup runs
**Then** a persistent backup is written to `/tmp/always-nvim-clipboard-backup` before the overwrite, surviving crashes for manual recovery (R1)

**Given** the cleanup function runs on normal exit
**When** the backup file exists
**Then** `/tmp/always-nvim-clipboard-backup` is deleted (R1)

**And** clipboard restoration succeeds on 100% of invocations across all exit paths (NFR5)
**And** temp files are cleaned on 100% of invocations (NFR6)
**And** no orphan processes remain after any exit path (NFR7)
**And** all variables in cleanup use `local` for function scope
**And** `printf '%s'` is used for all clipboard pipe operations (V3)

### Story 2.2: Abort Detection, Lock File & Stale Cleanup

As a user,
I want the tool to detect when I abort an edit (`:q!` or `:cq`), prevent double invocations, and clean up any stale files from previous crashes,
So that accidental hotkey presses have zero side effects and the tool never gets stuck.

**Acceptance Criteria:**

**Given** Neovim exits with a non-zero exit code (`:cq`)
**When** the exit code check runs (R5)
**Then** paste is skipped entirely — no text is pasted, clipboard is restored, temp file is cleaned up (FR15)

**Given** Neovim exits with exit code 0 (`:wq`) but the temp file is empty
**When** abort detection runs
**Then** this is treated as intentional (user saved empty content) — paste proceeds with empty content (Architecture P4)

**Given** Neovim exits with exit code 0 and the temp file content is identical to the original selection (Mode B)
**When** abort detection runs
**Then** this is treated as no-change — paste is skipped, clipboard is restored (FR15)

**Given** always-nvim is already running (lock file exists with a live PID)
**When** a second invocation attempts to start
**Then** it checks `/tmp/always-nvim.lock`, finds the PID is still running, and exits immediately with a descriptive message (R3)

**Given** always-nvim previously crashed and left a stale lock file (PID no longer running)
**When** a new invocation starts and checks the lock file
**Then** it detects the PID is dead, removes the stale lock, and proceeds normally (R3)

**Given** previous invocations crashed and left stale temp files
**When** stale file cleanup runs at init step 11
**Then** `find /tmp/always-nvim-* -mmin +60 -delete 2>/dev/null` removes temp files older than 60 minutes (R2)

**And** the tool functions correctly after 100 consecutive invocations without restart (NFR8)
**And** a clean abort (`:q!`) leaves zero trace — no text pasted, no clipboard change, no temp files (Journey 3)

### Story 2.3: Cleanup & Trap Tests

As a developer,
I want BATS tests that verify the cleanup function handles all exit paths correctly — normal exit, abort, signal interruption — and that lock file and stale cleanup work as specified,
So that the zero-side-effect guarantee has automated verification.

**Acceptance Criteria:**

**Given** `test/test_cleanup.bats` exists
**When** testing normal exit cleanup
**Then** it verifies: temp file is removed, lock file is removed, backup file is removed, clipboard is restored (FR16)

**Given** the cleanup tests run
**When** testing abort path (non-zero exit code)
**Then** it verifies: no paste occurs, clipboard is restored, temp file is cleaned (FR15)

**Given** the cleanup tests run
**When** testing cleanup idempotency
**Then** calling `cleanup()` twice does not error or produce side effects

**Given** the cleanup tests run
**When** testing stale file cleanup
**Then** it verifies `find /tmp/always-nvim-* -mmin +60 -delete` pattern removes old files (R2)

**Given** the cleanup tests run
**When** testing lock file behavior
**Then** it verifies: lock file prevents double invocation with live PID, stale lock (dead PID) is removed and allows new invocation (R3)

**And** all tests follow naming convention: `@test "cleanup: scenario description" { ... }`
**And** mock functions are sourced from `test/test_helper.sh`

## Epic 3: Installation & Distribution

The user can install always-nvim on a new machine with a single script that copies files, creates config, and shows WM-specific hotkey setup instructions for both i3 and Hyprland.

### Story 3.1: Install Script

As a user,
I want to run a single install script that sets up always-nvim on my machine with proper file placement, default config, and clear instructions for my window manager,
So that I can go from download to working hotkey with minimal manual steps.

**Acceptance Criteria:**

**Given** the user runs `./install.sh` from the repository root
**When** the install script executes
**Then** it copies `always-nvim`, `backends/x11.sh`, `backends/wayland.sh` to a user-accessible location on `$PATH` (FR29)

**Given** the install script runs
**When** the config directory does not exist
**Then** it creates `~/.config/always-nvim/` and writes an example `config` file with all `NA_*` variables commented with their defaults (FR30)

**Given** the install script runs
**When** the config directory already exists
**Then** it does not overwrite the existing config file (preserves user customizations)

**Given** the install script completes file operations
**When** it displays post-install instructions
**Then** it shows WM hotkey configuration snippets for both i3 (`bindsym $mod+e exec always-nvim`) and Hyprland (`bind = $mainMod, E, exec, always-nvim`) (FR31)

**Given** the install script displays WM instructions
**When** the user reads the output
**Then** it also shows window floating rules for both i3 (`for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center`) and Hyprland (`windowrulev2 = float,title:^(always-nvim)$` etc.) (FR31)

**And** the install script includes `# shellcheck shell=bash` directive (G3)
**And** the script uses `echo_error()` from the shell library for error messages if the library is available, otherwise falls back to plain stderr

## Epic 4: Enhanced Neovim Configuration

The user can configure always-nvim to use a dedicated Neovim config directory via the `NVIM_APPNAME` environment variable, enabling fast startup with a minimal config separate from their main Neovim setup.
**FRs covered:** FR28 (extended — new configurable option)
**NFRs addressed:** NFR1 (startup speed improvement with minimal config), NFR12 (line budget compliance)

### Story 4.1: NVIM_APPNAME Support

As a user,
I want to configure always-nvim to use a custom Neovim config directory via `NA_NVIM_APPNAME`,
So that I can use a minimal, fast Neovim configuration for quick edits without affecting my main setup.

**Acceptance Criteria:**

**Given** `NA_NVIM_APPNAME` is empty or unset (default)
**When** always-nvim launches Neovim
**Then** `NVIM_APPNAME` is NOT exported and Neovim uses `~/.config/nvim/` as normal

**Given** `NA_NVIM_APPNAME` is set to a non-empty value (e.g., `"always-nvim"`)
**When** always-nvim launches Neovim
**Then** `NVIM_APPNAME` is exported with that value before terminal launch, and Neovim uses `~/.config/<appname>/` for its configuration (D8)

**Given** `NA_NVIM_APPNAME` is set
**When** the terminal subprocess inherits the environment
**Then** only `NVIM_APPNAME` is affected — no other environment variables are modified

**And** the `config` reference file includes `NA_NVIM_APPNAME` with empty default
**And** the install script's example config includes `NA_NVIM_APPNAME` with descriptive comment
**And** `architecture.md` Config Variable Summary table includes `NA_NVIM_APPNAME`
**And** `architecture.md` Decision log includes D8 documenting the NVIM_APPNAME approach
**And** test coverage validates both empty and non-empty `NA_NVIM_APPNAME` behavior
**And** the main script stays within the 300-line budget (NFR12)
**And** the export line is placed immediately before the terminal launch command (init step 14)
