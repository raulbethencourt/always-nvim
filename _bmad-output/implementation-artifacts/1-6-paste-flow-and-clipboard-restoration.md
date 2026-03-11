# Story 1.6: Paste Flow & Clipboard Restoration

Status: done

## Story

As a user,
I want my edited text to appear in the source application after I save and close Neovim, with my original clipboard contents preserved,
So that the editing result lands where I need it without disrupting my clipboard.

## Acceptance Criteria (BDD)

1. **Given** the script starts and backends are available **When** the active window is recorded before terminal spawn **Then** `backend_get_active_window()` saves the source window handle to a variable (FR21)
2. **Given** the script starts and backends are available **When** clipboard save runs at init step 9 **Then** `backend_get_clipboard()` saves the current clipboard contents to `SAVED_CLIPBOARD` (FR4)
3. **Given** Neovim exits with exit code 0 (`:wq`) and the temp file has content **When** the paste flow executes **Then** the temp file contents are read, set to clipboard via `printf '%s' "$content" | backend_set_clipboard()`, the source window is refocused via `backend_refocus_window()`, then `backend_simulate_paste()` simulates Ctrl+V (FR8, FR14, FR22, FR24)
4. **Given** paste simulation has been sent **When** `$NA_PASTE_DELAY` seconds have elapsed **Then** the original clipboard is restored via `printf '%s' "$SAVED_CLIPBOARD" | backend_set_clipboard()` (FR5, FR25, D6)
5. **Given** a configurable focus delay is set **When** the source window is refocused **Then** the script waits `$NA_FOCUS_DELAY` seconds before simulating paste (FR23)
6. **And** all clipboard pipe operations use `printf '%s'` — never `echo` (V3)

## Tasks / Subtasks

- [x] Task 1: Fill init step 9 — save clipboard (AC: #2)
  - [x] 1.1: `SAVED_CLIPBOARD=$(backend_get_clipboard)`

- [x] Task 2: Record active window before terminal spawn (AC: #1)
  - [x] 2.1: `source_window=$(backend_get_active_window)` with `|| source_window=""` fallback

- [x] Task 3: Post-edit paste flow (AC: #3, #5, #6)
  - [x] 3.1: Check `nvim_exit == 0` and temp file has content
  - [x] 3.2: Read temp file content via `cat "$tmpfile"`
  - [x] 3.3: Set clipboard via `printf '%s' "$content" | backend_set_clipboard`
  - [x] 3.4: Refocus source window via `backend_refocus_window "$source_window"`
  - [x] 3.5: Sleep `$NA_FOCUS_DELAY` before paste
  - [x] 3.6: Simulate paste via `backend_simulate_paste`

- [x] Task 4: Clipboard restoration after paste (AC: #4)
  - [x] 4.1: Sleep `$NA_PASTE_DELAY` after paste
  - [x] 4.2: Restore via `printf '%s' "$SAVED_CLIPBOARD" | backend_set_clipboard` — runs unconditionally

- [x] Task 5: Create BATS tests (AC: all)
  - [x] 5.1: 11 structural tests + 4 functional tests with mocked backends
  - [x] 5.2: Functional: exit 0 + content → full paste flow + restore
  - [x] 5.3: Functional: exit 0 + empty → skip paste, still restore
  - [x] 5.4: Functional: exit non-zero → skip paste, still restore
  - [x] 5.5: Functional: no source window → skip refocus, still paste

## Dev Agent Record

### Agent Model Used
claude-opus-4.6 (github-copilot)

### Completion Notes
- Init step 9: Saves clipboard to `SAVED_CLIPBOARD` and records `source_window` (with fallback on failure).
- Post-edit: Checks `nvim_exit == 0` and non-empty content before paste flow.
- Paste flow: set clipboard → refocus → focus delay → paste → paste delay.
- Clipboard restore is unconditional (runs on success, abort, and empty content).
- All clipboard operations use `printf '%s'` (V3 compliance).
- 15 new BATS tests (11 structural + 4 functional).
- Full suite: 87/87 passing.

### File List
- always-nvim (modified) — Init step 9 filled, post-edit paste flow added (27 new lines)
- test/11_paste_flow.bats (new) — 15 BATS tests for paste flow & clipboard restoration

## Change Log
- 2026-03-11: Story 1.6 implemented — paste flow, clipboard save/restore, 15 BATS tests, all 87 tests passing.
