# Story 1.5: Terminal Spawn & Neovim Orchestration

Status: done

## Story

As a user,
I want a floating Neovim terminal to appear when I press the hotkey and the script to wait until I'm done editing,
So that I can edit text with full Neovim capabilities in a distraction-free floating window.

## Acceptance Criteria (BDD)

1. **Given** mode detection and temp file creation are complete **When** the terminal is launched **Then** `$NA_TERMINAL_CMD` is executed with Neovim, the mode-aware arguments, any `$NA_NVIM_ARGS`, and the temp file path (FR17, FR18, FR19, D5)
2. **Given** the terminal window title is set to `always-nvim` **When** the window manager processes the window **Then** configured floating/sizing rules match on the title string (FR17)
3. **Given** the terminal has been spawned **When** the script continues execution **Then** it blocks (waits synchronously) until the terminal process exits (FR20)
4. **Given** Neovim is running inside the terminal **When** the user types `:wq` or `:q!` or `:cq` **Then** Neovim exits, the terminal closes, and the script unblocks with Neovim's exit code available
5. **And** this corresponds to init step 14 in the initialization order
6. **And** no background processes are spawned — fully synchronous execution (NFR7)

## Tasks / Subtasks

- [x] Task 1: Implement init step 14 — terminal + nvim launch (AC: #1, #2, #3, #4)
  - [x] 1.1: Build full command: `$NA_TERMINAL_CMD nvim "${nvim_args[@]}" "$tmpfile"`
  - [x] 1.2: Capture nvim exit code in `nvim_exit` variable
  - [x] 1.3: Synchronous execution — no `&` or background processes

- [x] Task 2: Create BATS tests (AC: all)
  - [x] 2.1: Structural test: init step 14 comment exists after step 13
  - [x] 2.2: Structural test: NA_TERMINAL_CMD used in launch command
  - [x] 2.3: Structural test: nvim_args and tmpfile used in launch
  - [x] 2.4: Structural test: exit code captured

## Dev Agent Record

### Agent Model Used
claude-opus-4.6 (github-copilot)

### Completion Notes
- Init step 14: `$NA_TERMINAL_CMD nvim "${nvim_args[@]}" "$tmpfile"` — synchronous, blocks until exit.
- Exit code captured in `nvim_exit=$?` for use by Story 1.6 post-edit logic.
- `SC2086` disabled for `$NA_TERMINAL_CMD` (intentional word-splitting of terminal command + flags).
- 5 new BATS structural tests, all passing.
- Full suite: 72/72 passing.

### File List
- always-nvim (modified) — Init step 14 added (4 lines)
- test/10_terminal_spawn.bats (new) — 5 BATS tests for terminal spawn

## Change Log
- 2026-03-11: Story 1.5 implemented — terminal spawn with nvim, exit code capture, 5 BATS tests, all 72 tests passing.
