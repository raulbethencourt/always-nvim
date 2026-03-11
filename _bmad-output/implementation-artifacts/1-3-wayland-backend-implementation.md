# Story 1.3: Wayland Backend Implementation

Status: done

## Story

As a developer,
I want the Wayland/Hyprland backend to implement all 6 interface functions using wl-clipboard, wtype, hyprctl, and jq with proper normalization,
So that the main script can interact with the Wayland display server identically to X11.

## Acceptance Criteria (BDD)

1. **Given** the Wayland backend is sourced **When** `backend_get_selection()` is called with text in the primary selection **Then** it returns the selected text on stdout with exit code 0
2. **Given** the Wayland backend is sourced **When** `backend_get_selection()` is called with no primary selection **Then** it returns empty stdout with exit code 0 (V1: normalizes `wl-paste --primary` exit 1)
3. **Given** the Wayland backend is sourced **When** `backend_get_clipboard()` is called with an empty clipboard **Then** it returns empty stdout with exit code 0 (V2: same normalization)
4. **Given** the Wayland backend is sourced **When** content is piped to `backend_set_clipboard()` **Then** the system clipboard contains the exact content with no trailing newline added (V3)
5. **Given** the Wayland backend is sourced **When** `backend_simulate_paste()` is called **Then** it simulates a Ctrl+V keystroke via wtype
6. **Given** the Wayland backend is sourced **When** `backend_get_active_window()` is called and a window is focused **Then** it returns an opaque window handle from `hyprctl activewindow -j` via jq with exit code 0
7. **Given** the Wayland backend is sourced **When** `backend_get_active_window()` is called and `hyprctl` returns `"0x0"` or address is `"null"` **Then** it returns exit code 1 (V4)
8. **Given** the Wayland backend is sourced and a window handle was previously obtained **When** `backend_refocus_window()` is called with that handle **Then** `hyprctl dispatch` is used to refocus the window
9. **Given** required Wayland tools (wl-paste, wl-copy, wtype, hyprctl, jq) are not installed **When** dependency checking runs **Then** the script calls `error_exit()` with a descriptive message (FR3)
10. **And** the backend file is under 50 lines of Bash excluding comments (NFR13)
11. **And** the file includes `# shellcheck shell=bash` directive (G3)
12. **And** all functions use the `backend_` prefix (ADC-1)
13. **And** all functions follow the error contract (ADC-2)
14. **And** both backends produce identical behavior from the caller's perspective (NFR9)

## Tasks / Subtasks

- [x] Task 1: Implement `backend_get_selection` (AC: #1, #2)
  - [x] 1.1: Use `wl-paste --primary --no-newline` with `|| true` normalization (V1)
  - [x] 1.2: Use `printf '%s'` for output (V3)

- [x] Task 2: Implement `backend_get_clipboard` (AC: #3)
  - [x] 2.1: Use `wl-paste --no-newline` with `|| true` normalization (V2)
  - [x] 2.2: Use `printf '%s'` for output (V3)

- [x] Task 3: Implement `backend_set_clipboard` (AC: #4)
  - [x] 3.1: Use `wl-copy` reading from stdin

- [x] Task 4: Implement `backend_simulate_paste` (AC: #5)
  - [x] 4.1: Use `wtype -M ctrl -k v -m ctrl`

- [x] Task 5: Implement `backend_get_active_window` (AC: #6, #7)
  - [x] 5.1: Use `hyprctl activewindow -j` with `jq` to extract address
  - [x] 5.2: Check for `"0x0"`, `"null"`, or empty address → return exit 1 (V4)

- [x] Task 6: Implement `backend_refocus_window` (AC: #8)
  - [x] 6.1: Use `hyprctl dispatch focuswindow "address:$window"`

- [x] Task 7: Verify dependency checks in main script (AC: #9)
  - [x] 7.1: Confirmed `always-nvim` checks for wl-paste, wl-copy, wtype, hyprctl, jq (done in Story 1.1)

- [x] Task 8: Create BATS tests (AC: all)
  - [x] 8.1: Create `test/08_backend_contract_wayland.bats` with mocked commands
  - [x] 8.2: All 11 tests pass including V1, V2, V4 regression tests

## Dev Agent Record

### Agent Model Used
claude-opus-4.6 (github-copilot)

### Completion Notes
- Implemented `backends/wayland.sh` with all 6 functions (under 50 lines excluding comments).
- V1: `backend_get_selection()` normalizes `wl-paste --primary` exit 1 to exit 0 via `|| true`.
- V2: `backend_get_clipboard()` normalizes `wl-paste` exit 1 to exit 0 via `|| true`.
- V3: All output uses `printf '%s'` — no trailing newlines.
- V4: `backend_get_active_window()` checks for `"0x0"`, `"null"`, or empty address and returns exit 1.
- Paste simulation uses `wtype -M ctrl -k v -m ctrl` for proper modifier handling.
- Refocus uses `hyprctl dispatch focuswindow "address:$window"`.
- 11 BATS tests with mocked `wl-paste`, `wl-copy`, `wtype`, `hyprctl`, `jq`.
- Full suite: 54/54 passing.

### File List
- backends/wayland.sh (modified) — Full Wayland backend implementation
- test/08_backend_contract_wayland.bats (new) — 11 BATS tests for Wayland backend contract

## Change Log
- 2026-03-11: Story 1.3 implemented — Wayland backend with V1-V4 fixes, 11 BATS tests, all 54 tests passing.
