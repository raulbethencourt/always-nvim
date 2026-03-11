# Story 1.4: Mode Detection & Temp File Preparation

Status: done

## Story

As a user,
I want the tool to automatically detect whether I have text selected (edit mode) or not (insert mode) and prepare the editing environment accordingly,
So that I get the right behavior without any manual mode switching.

## Acceptance Criteria (BDD)

1. **Given** no text is currently selected (primary selection is empty) **When** mode detection runs via `backend_get_selection()` **Then** Mode A (insert new) is determined and an empty temp file is created via `mktemp /tmp/always-nvim-XXXXXX.$NA_FILETYPE` (FR9, FR10, FR12)
2. **Given** text is currently selected (primary selection contains content) **When** mode detection runs via `backend_get_selection()` **Then** Mode B (edit selection) is determined, a temp file is created, and the selection is written to it using `printf '%s'` (FR9, FR11, FR12, FR13)
3. **Given** Mode A is detected **When** Neovim launch arguments are assembled **Then** `-c "startinsert"` is included so the user starts typing immediately (D4)
4. **Given** Mode B is detected **When** Neovim launch arguments are assembled **Then** Neovim opens in normal mode with the selected text loaded (D4)
5. **Given** the user has set `NA_NVIM_ARGS` in config **When** Neovim launch arguments are assembled **Then** the user's additional arguments are appended (FR19)
6. **And** the temp file uses the configured `NA_FILETYPE` as its extension (D3)
7. **And** all content written to temp file uses `printf '%s'` — never `echo` (V3)
8. **And** this corresponds to init steps 12-13 in the initialization order

## Tasks / Subtasks

- [x] Task 1: Add init steps 9-11 placeholders in main script (AC: #8)
  - [x] 1.1: Add comment placeholders for clipboard save, trap upgrade, stale cleanup

- [x] Task 2: Implement mode detection — init step 12 (AC: #1, #2)
  - [x] 2.1: Call `backend_get_selection()` and capture result
  - [x] 2.2: Determine Mode A (empty selection) vs Mode B (has selection)

- [x] Task 3: Create temp file — init step 13 (AC: #1, #2, #6, #7)
  - [x] 3.1: Create temp file via `mktemp /tmp/always-nvim-XXXXXX.$NA_FILETYPE`
  - [x] 3.2: In Mode B, write selection to temp file using `printf '%s'`

- [x] Task 4: Assemble Neovim launch arguments (AC: #3, #4, #5)
  - [x] 4.1: Mode A → add `-c "startinsert"` to nvim args
  - [x] 4.2: Mode B → no extra mode args (normal mode)
  - [x] 4.3: Append `$NA_NVIM_ARGS` from config

- [x] Task 5: Create BATS tests (AC: all)
  - [x] 5.1: Create `test/09_mode_detection.bats` with mocked backend
  - [x] 5.2: Test Mode A detection + empty temp file + startinsert arg
  - [x] 5.3: Test Mode B detection + temp file content + normal mode
  - [x] 5.4: Test NA_NVIM_ARGS appending
  - [x] 5.5: Test temp file extension uses NA_FILETYPE
  - [x] 5.6: Test printf '%s' usage (no echo for content)

## Dev Agent Record

### Agent Model Used
claude-opus-4.6 (github-copilot)

### Completion Notes
- Added init steps 9-11 as comment placeholders (to be filled by Stories 1.6, 2.1, 2.2).
- Init step 12: Mode detection via `backend_get_selection()` — empty = Mode A, non-empty = Mode B.
- Init step 13: Temp file via `mktemp /tmp/always-nvim-XXXXXX.$NA_FILETYPE`, pre-filled in Mode B with `printf '%s'`.
- Neovim args built as bash array: Mode A adds `-c "startinsert"`, `$NA_NVIM_ARGS` always appended.
- 13 new BATS tests (7 structural + 6 functional) — all passing.
- Full suite: 67/67 passing.

### File List
- always-nvim (modified) — Init steps 9-13 added (35 new lines)
- test/09_mode_detection.bats (new) — 13 BATS tests for mode detection & temp file

## Change Log
- 2026-03-11: Story created and implementation started.
- 2026-03-11: Story 1.4 implemented — mode detection, temp file, nvim args, 13 BATS tests, all 67 tests passing.
