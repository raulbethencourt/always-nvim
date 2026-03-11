# Story 1.7: Test Helper, Backend Contract & Mode Detection Tests

Status: complete

## Story

As a developer,
I want a centralized test helper with mock backend functions and BATS tests that verify the 6-function interface contract, Wayland normalization fixes, and Mode A/B detection logic,
So that backend parity is verified, contract violations V1-V4 have regression coverage, and mode detection regressions are caught.

## Acceptance Criteria (BDD)

1. **Given** the test infrastructure is being set up **When** `test/test_helper.sh` is created **Then** it provides mock implementations for all 6 `backend_*` functions that tests can override per-scenario (ADC-7)

2. **Given** `test/test_backend_contract.bats` exists **When** `bats test/test_backend_contract.bats` runs **Then** it verifies: `backend_get_selection()` returns exit 0 + empty stdout when no selection exists — for both backends (V1 regression)

3. **Given** the backend contract tests run **When** testing clipboard operations **Then** it verifies: `backend_get_clipboard()` returns exit 0 + empty stdout when clipboard is empty — for both backends (V2 regression)

4. **Given** the backend contract tests run **When** testing clipboard data integrity **Then** it verifies: `backend_set_clipboard()` preserves exact content without trailing newline addition (V3 regression)

5. **Given** the backend contract tests run **When** testing Wayland active window edge case **Then** it verifies: `backend_get_active_window()` returns exit 1 when `hyprctl` reports null/zero address (V4 regression)

6. **Given** `test/test_mode_detection.bats` exists **When** testing with empty primary selection (mocked) **Then** mode detection returns Mode A (insert new) (FR10)

7. **Given** the mode detection tests run **When** testing with non-empty primary selection (mocked) **Then** mode detection returns Mode B (edit selection) and the selection content is captured (FR11)

8. **Given** the mode detection tests run **When** testing temp file creation in Mode A **Then** an empty temp file is created with the configured `$NA_FILETYPE` extension (FR12)

9. **Given** the mode detection tests run **When** testing temp file creation in Mode B **Then** the temp file is created and pre-filled with the selection content using `printf '%s'` (FR13)

10. **Given** `test/test_clipboard.bats` exists **When** testing the save/restore cycle **Then** it verifies clipboard contents are identical before and after a simulated invocation (FR4, FR5)

11. **Given** the clipboard tests run **When** testing content with special characters (newlines, tabs, unicode, empty string) **Then** `printf '%s'` preserves exact content through the save -> overwrite -> restore cycle (V3)

12. **Given** the clipboard tests run **When** testing the backup file mechanism **Then** it verifies `/tmp/always-nvim-clipboard-backup` is created before clipboard overwrite and deleted on normal cleanup (R1)

13. **And** all tests follow naming convention: `@test "component: scenario description" { ... }`
14. **And** test files include `setup()` that loads `test_helper`
15. **And** mock functions are sourced from `test/test_helper.sh`

## Tasks / Subtasks

- [x] Task 1: Create centralized `test/test_helper.sh` with mock backend functions (AC: #1)
  - [x] 1.1: Create `test/test_helper.sh` with default mock implementations for all 6 `backend_*` functions
  - [x] 1.2: Mock `backend_get_selection()` — returns configurable content via `MOCK_SELECTION` var (default: empty)
  - [x] 1.3: Mock `backend_get_clipboard()` — returns configurable content via `MOCK_CLIPBOARD` var (default: empty)
  - [x] 1.4: Mock `backend_set_clipboard()` — captures stdin to file at `MOCK_STATE_DIR/clipboard_set` (pipe-safe via file instead of var)
  - [x] 1.5: Mock `backend_simulate_paste()` — sets `MOCK_PASTE_CALLED=1` flag + file marker
  - [x] 1.6: Mock `backend_get_active_window()` — returns configurable `MOCK_WINDOW_ID` (default: "12345")
  - [x] 1.7: Mock `backend_refocus_window()` — captures arg to `MOCK_REFOCUS_ARG` var + file
  - [x] 1.8: Ensure mocks are overridable per-test (functions can be redefined in individual tests)

- [x] Task 2: Create `test/13_backend_contract.bats` — V1-V4 regression tests (AC: #2, #3, #4, #5)
  - [x] 2.1: Test `backend_get_selection()` returns exit 0 + empty stdout when selection is empty — X11 backend with mocked `xclip` returning exit 1
  - [x] 2.2: Test `backend_get_selection()` returns exit 0 + empty stdout when selection is empty — Wayland backend with mocked `wl-paste --primary` returning exit 1
  - [x] 2.3: Test `backend_get_clipboard()` returns exit 0 + empty stdout when clipboard is empty — X11 backend
  - [x] 2.4: Test `backend_get_clipboard()` returns exit 0 + empty stdout when clipboard is empty — Wayland backend
  - [x] 2.5: Test `backend_set_clipboard()` preserves exact content without trailing newline — X11 backend (pipe `printf '%s' "test"` and verify)
  - [x] 2.6: Test `backend_set_clipboard()` preserves exact content without trailing newline — Wayland backend
  - [x] 2.7: Test `backend_get_active_window()` returns exit 1 when Wayland `hyprctl` returns address `"0x0"` (V4)
  - [x] 2.8: Test `backend_get_active_window()` returns exit 1 when Wayland `hyprctl` returns address `"null"` (V4)
  - [x] 2.9: Test `backend_get_active_window()` returns exit 0 + valid address when Wayland `hyprctl` returns valid window

- [x] Task 3: Create `test/14_mode_detection.bats` — Mode A/B detection tests (AC: #6, #7, #8, #9)
  - [x] 3.1: Test Mode A: empty primary selection -> mode=A determined (FR10)
  - [x] 3.2: Test Mode B: non-empty primary selection -> mode=B determined, selection captured (FR11)
  - [x] 3.3: Test Mode A: empty temp file created with `$NA_FILETYPE` extension (FR12)
  - [x] 3.4: Test Mode B: temp file pre-filled with selection content via `printf '%s'` (FR13)
  - [x] 3.5: Test Mode A: nvim_args includes `-c "startinsert"`
  - [x] 3.6: Test Mode B: nvim_args does NOT include `startinsert`
  - [x] 3.7: Test `NA_NVIM_ARGS` appended in both modes

- [x] Task 4: Create `test/15_clipboard_cycle.bats` — clipboard save/restore cycle tests (AC: #10, #11, #12)
  - [x] 4.1: Test save/restore cycle: clipboard contents identical after simulated invocation (FR4, FR5)
  - [x] 4.2: Test special chars: newlines preserved through save -> overwrite -> restore
  - [x] 4.3: Test special chars: tabs preserved through cycle
  - [x] 4.4: Test special chars: unicode preserved through cycle
  - [x] 4.5: Test special chars: empty string handled gracefully
  - [x] 4.6: Test backup file: `/tmp/always-nvim-clipboard-backup` created before clipboard overwrite (R1 spec)
  - [x] 4.7: Test backup file: cleanup removes backup file on normal exit (R1 spec)

- [x] Task 5: Verify all tests pass and no regressions (AC: all)
  - [x] 5.1: Run `./test/run_tests.sh` — all existing 87 tests pass
  - [x] 5.2: Run new test files individually to confirm pass
  - [x] 5.3: Run full suite to confirm no regressions (117/117)

## Dev Notes

### Architecture Requirements

- **ADC-7:** Backend test strategy uses inline mocks via centralized `test/test_helper.sh` to prevent mock drift. Each test file sources the helper.
- **ADC-1:** Backend interface = 6 functions: `backend_get_selection()`, `backend_get_clipboard()`, `backend_set_clipboard()`, `backend_simulate_paste()`, `backend_get_active_window()`, `backend_refocus_window()`
- **ADC-2:** Error contract: success = stdout + exit 0, failure = exit 1 + stderr, empty result = empty stdout + exit 0

### Contract Violations Being Tested

| Violation | Description | Required Fix Pattern |
|---|---|---|
| V1 | `wl-paste --primary` returns exit 1 on empty selection (X11 returns exit 0) | `result=$(wl-paste --primary 2>/dev/null) \|\| true; printf '%s' "$result"` |
| V2 | `wl-paste` returns exit 1 on empty clipboard (X11 returns exit 0) | Same normalization pattern as V1 |
| V3 | Using `echo` adds trailing newline, corrupting clipboard data | Use `printf '%s'` for ALL clipboard pipe operations |
| V4 | `hyprctl activewindow -j` may return `"0x0"` or `"null"` when no window focused | Check for null/zero address, return exit 1 |

### Critical Implementation Notes

#### Existing Test Infrastructure

- **Test runner:** `test/run_tests.sh` runs `bats test/*.bats` (sorted by filename)
- **Existing test_helper:** `test/test_helper.bash` (note: `.bash` extension, not `.sh`) provides `PROJECT_ROOT`, `SCRIPT_PATH`, and basic `setup()` with `SHELLTOOLSPATH` env var
- **BATS binary:** vendored at `test/bats/bin/bats`
- **Current test count:** 87 tests, all passing
- **Test file naming:** `NN_description.bats` (e.g., `01_file_structure.bats`, `07_backend_contract_x11.bats`)

#### CRITICAL: test_helper.sh vs test_helper.bash

The story's AC says to create `test/test_helper.sh` but the project already has `test/test_helper.bash`. The epics spec says `test/test_helper.sh` (architecture doc too). However, the actual project uses `test/test_helper.bash` with BATS's `load test_helper` convention (BATS auto-appends `.bash`).

**Decision:** Create `test/test_helper.sh` as the **centralized mock helper** per the architecture spec. This is a DIFFERENT file from `test/test_helper.bash` (which is the BATS load helper). The mock helper should be sourced explicitly via `source "$PROJECT_ROOT/test/test_helper.sh"` in test setups that need mock backends.

#### Existing Backend Contract Tests

Stories 1.2 and 1.3 already created tests in:
- `test/07_backend_contract_x11.bats` — 6 tests verifying X11 backend function calls
- `test/08_backend_contract_wayland.bats` — 10 tests verifying Wayland backend with V1, V2, V4 normalization

These tests use **inline mock executables** (temp directory with mock scripts for xclip, xdotool, wl-paste, etc.) NOT the centralized test_helper pattern. The new `test/test_backend_contract.bats` should provide **additional** contract verification focused on:
1. Cross-backend parity (same behavior from both backends)
2. V3 trailing newline regression (not yet covered)
3. Empty selection/clipboard normalization verified against the **error contract** (ADC-2)

#### Existing Mode Detection Tests

`test/09_mode_detection.bats` already has 12 tests covering:
- Structural tests (init steps, code patterns)
- Functional tests (Mode A/B, filetype, nvim_args)

The new `test/test_mode_detection.bats` should use the **centralized mock helper** pattern and may consolidate/enhance the existing functional tests rather than duplicating them.

#### Test File Numbering

Existing tests: `01` through `11`. New test files should continue the sequence:
- `12_test_helper.bats` — tests for the test_helper.sh itself (optional, if needed)
- `13_backend_contract.bats` — the new cross-backend contract tests
- `14_mode_detection_enhanced.bats` — enhanced mode detection tests using mock helper
- `15_clipboard_cycle.bats` — clipboard save/restore cycle tests

OR per the architecture spec naming: `test_backend_contract.bats`, `test_mode_detection.bats`, `test_clipboard.bats`. **Use the numbered convention** to match the established project pattern.

### Testing Patterns Established in Previous Stories

```bash
# Pattern 1: Mock external tools via temp directory (Stories 1.2, 1.3)
setup() {
  MOCK_DIR=$(mktemp -d)
  export LOG_FILE="$MOCK_DIR/mock_log"
  export PATH="$MOCK_DIR:$PATH"
  # Create mock executables...
  source "$PROJECT_ROOT/backends/x11.sh"
}

# Pattern 2: Extracted logic in subshell (Story 1.4)
run_mode_detection() {
  bash -c "
    backend_get_selection() { printf '%s' '$mock_selection'; }
    # ... extracted logic ...
  "
}

# Pattern 3: Structural grep tests (Stories 1.1-1.6)
@test "description" {
  grep -q 'pattern' "$SCRIPT_PATH"
}
```

### Project Structure Notes

- All test files in `test/` directory, flat structure
- `test/bats/` is the vendored BATS binary (submodule)
- `test/test_helper.bash` is the BATS standard helper (loaded via `load test_helper`)
- `test/test_helper.sh` will be the NEW centralized mock file (sourced explicitly)
- `test/run_tests.sh` runs all `test/*.bats` files

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Testing Strategy] — BATS framework, test-first targets V1-V3
- [Source: _bmad-output/planning-artifacts/architecture.md#ADC-7] — Centralized test helper mock strategy
- [Source: _bmad-output/planning-artifacts/architecture.md#Interface Contract Verification] — V1-V4 violations
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns] — BATS test naming convention
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.7] — Full acceptance criteria
- [Source: _bmad-output/implementation-artifacts/1-6-paste-flow-and-clipboard-restoration.md] — Previous story learnings
- [Source: test/07_backend_contract_x11.bats] — Existing X11 contract test patterns
- [Source: test/08_backend_contract_wayland.bats] — Existing Wayland contract test patterns
- [Source: test/09_mode_detection.bats] — Existing mode detection test patterns
- [Source: test/test_helper.bash] — Existing BATS helper file

### Previous Story Intelligence (from Story 1.6)

- All 87 tests passing as of story 1.6 completion
- Agent model: claude-opus-4.6 (github-copilot)
- Clipboard operations use `printf '%s'` consistently (V3 compliance)
- Functional tests use extracted-logic-in-subshell pattern
- `source_window` fallback with `|| source_window=""` pattern
- Clipboard restore is unconditional (runs on all paths)

### Anti-Patterns to Avoid

1. **DO NOT** create duplicate tests that already exist in `07_backend_contract_x11.bats` and `08_backend_contract_wayland.bats` — focus on NEW coverage (cross-backend parity, V3 newline, save/restore cycle)
2. **DO NOT** use `echo` for data in tests — always `printf '%s'`
3. **DO NOT** use `function` keyword for bash functions
4. **DO NOT** create tests with vague names — use `@test "component: scenario description" { ... }`
5. **DO NOT** modify existing test files — create new ones
6. **DO NOT** modify the main `always-nvim` script — this story is test-only
7. **DO NOT** modify backend files — this story is test-only

### Backup File Mechanism (R1) — Not Yet Implemented

AC #12 references `/tmp/always-nvim-clipboard-backup` but this mechanism is part of **Story 2.1** (Two-Phase Trap & Cleanup System). The backup file write and cleanup are NOT yet in the main script. For the clipboard tests (Task 4.6, 4.7), the dev agent should:
- Write tests that verify the backup file pattern in **isolation** (mock the flow)
- Tests should verify the concept/pattern works, not that it's wired into the main script
- These tests serve as **specification tests** that Story 2.1 must satisfy

## Dev Agent Record

### Agent Model Used

claude-opus-4.6 (github-copilot)

### Debug Log References

- No debug issues encountered. All tests passed on first run.

### Completion Notes List

1. **test_helper.sh uses file-based capture** — `backend_set_clipboard()` writes stdin to `$MOCK_STATE_DIR/clipboard_set` instead of a shell variable, because piped commands run in subshells and variable assignments don't propagate. Helper functions `mock_get_clipboard_set()`, `mock_paste_was_called()`, `mock_get_refocus_arg()` read the files. `mock_reset()` cleans up.
2. **Test file naming**: Used numbered convention (`13_`, `14_`, `15_`) matching project pattern, not the `test_` prefix from the AC.
3. **13_backend_contract.bats**: 13 tests — cross-backend parity (V1/V2 for both X11+Wayland), V3 trailing newline (single-line + multiline for both backends), V4 null/zero/valid address, function completeness checks. Does NOT duplicate tests from `07_`/`08_`.
4. **14_mode_detection.bats**: 10 tests — uses centralized `test_helper.sh` mock pattern (ADC-7) instead of inline mocks. Covers Mode A/B, filetype extension, multiline V3 byte-count verification, startinsert, NA_NVIM_ARGS.
5. **15_clipboard_cycle.bats**: 7 tests — save→overwrite→restore cycle with file-backed clipboard mock. Special chars: newlines, tabs, unicode, empty string. R1 backup file tests are specification tests (pattern verified in isolation, Story 2.1 wires into main script).
6. **Total test count**: 87 → 117 (+30 new tests). Zero regressions.

### File List

| File | Action | Description |
|------|--------|-------------|
| `test/test_helper.sh` | **Created** | Centralized mock backend — 6 functions, MOCK_STATE_DIR file-based capture, mock_reset() |
| `test/13_backend_contract.bats` | **Created** | 13 cross-backend V1-V4 regression tests |
| `test/14_mode_detection.bats` | **Created** | 10 mode detection tests using centralized mock helper |
| `test/15_clipboard_cycle.bats` | **Created** | 7 clipboard save/restore cycle + R1 spec tests |

### Change Log

| Task | AC | Tests Added | Notes |
|------|-----|-------------|-------|
| Task 1 | #1 | — | `test/test_helper.sh` created with all 6 mocks + file capture + helpers |
| Task 2 | #2,#3,#4,#5 | 13 | V1/V2 parity, V3 newline (new coverage), V4 null/zero, function completeness |
| Task 3 | #6,#7,#8,#9 | 10 | Mode A/B via mock helper, filetype, startinsert, NA_NVIM_ARGS, multiline V3 |
| Task 4 | #10,#11,#12 | 7 | Save/restore cycle, special chars (newlines/tabs/unicode/empty), R1 spec tests |
| Task 5 | all | — | 117/117 passing, zero regressions |
