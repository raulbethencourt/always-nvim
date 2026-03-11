# Story 1.2: X11 Backend Implementation

Status: complete

## Story

As a developer,
I want the X11 backend to implement all 6 interface functions using xdotool and xclip,
So that the main script can interact with the X11 display server through a clean abstraction.

## Acceptance Criteria (BDD)

1. **Given** the X11 backend is sourced **When** `backend_get_selection()` is called with text in the primary selection **Then** it returns the selected text on stdout with exit code 0
2. **Given** the X11 backend is sourced **When** `backend_get_selection()` is called with no primary selection **Then** it returns empty stdout with exit code 0
3. **Given** the X11 backend is sourced **When** `backend_get_clipboard()` is called **Then** it returns current clipboard contents on stdout with exit code 0
4. **Given** the X11 backend is sourced **When** content is piped to `backend_set_clipboard()` **Then** the system clipboard contains the exact content with no trailing newline added
5. **Given** the X11 backend is sourced **When** `backend_simulate_paste()` is called **Then** it simulates a Ctrl+V keystroke via xdotool
6. **Given** the X11 backend is sourced **When** `backend_get_active_window()` is called **Then** it returns an opaque window handle on stdout with exit code 0
7. **Given** the X11 backend is sourced and a window handle was previously obtained **When** `backend_refocus_window()` is called with that handle **Then** the specified window regains focus
8. **Given** required X11 tools (xclip, xdotool) are not installed **When** dependency checking runs via `check_for_cmd_in_path()` **Then** the script calls `error_exit()` with a descriptive message naming the missing tool
9. **And** the backend file is under 50 lines of Bash excluding comments
10. **And** the file includes `# shellcheck shell=bash` directive
11. **And** all functions use the `backend_` prefix
12. **And** all functions follow the error contract: success = stdout + exit 0, failure = exit 1 + stderr

## Tasks

- [x] Task 1: Create `backends/x11.sh` (if not exists)
  - [x] 1.1: Ensure file exists with correct permissions
  - [x] 1.2: Add `# shellcheck shell=bash` directive
  - [x] 1.3: Add contract header comment

- [x] Task 2: Implement `backend_get_selection` and `backend_get_clipboard`
  - [x] 2.1: Use `xclip -o -selection primary/clipboard`
  - [x] 2.2: Handle empty selection exit code (exit 1 -> exit 0) via `|| true` normalization
  - [x] 2.3: Ensure output goes to stdout

- [x] Task 3: Implement `backend_set_clipboard`
  - [x] 3.1: Read from stdin
  - [x] 3.2: Use `xclip -selection clipboard -i`

- [x] Task 4: Implement window management functions
  - [x] 4.1: `backend_get_active_window`: `xdotool getactivewindow`
  - [x] 4.2: `backend_refocus_window`: `xdotool windowactivate "$1"`

- [x] Task 5: Implement paste simulation
  - [x] 5.1: `backend_simulate_paste`: `xdotool key --clearmodifiers ctrl+v`

- [x] Task 6: Verification
  - [x] 6.1: Run contract tests (create if needed)
  - [x] 6.2: Manual verification (optional)

## Dev Agent Record

### Completion Notes
- Implemented `backends/x11.sh` with all 6 required functions.
- Handled `xclip` exit code 1 normalization for empty selections using `|| true`.
- Verified implementation with `test/test_07_backend_contract_x11.sh` (executed manually during Story 1.2 context creation).
- Code is concise (under 50 lines) and shellcheck compliant.
- User manually reviewed and approved changes with one minor update.

### File List
- backends/x11.sh (modified)
- test/test_07_backend_contract_x11.sh (new)

## Change Log
- 2026-03-11: Story 1.2 implemented and verified.
