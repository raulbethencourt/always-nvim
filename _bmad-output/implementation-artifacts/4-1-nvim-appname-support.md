# Story 4.1: NVIM_APPNAME Support

Status: done

## Story

As a user,
I want to configure always-nvim to use a custom Neovim config directory via `NA_NVIM_APPNAME`,
so that I can use a minimal, fast Neovim configuration for quick edits without affecting my main setup.

## Acceptance Criteria (BDD)

1. **Given** `NA_NVIM_APPNAME` is empty or unset (default) **When** always-nvim launches Neovim **Then** `NVIM_APPNAME` is NOT exported and Neovim uses `~/.config/nvim/` as normal

2. **Given** `NA_NVIM_APPNAME` is set to a non-empty value (e.g., `"always-nvim"`) **When** always-nvim launches Neovim **Then** `NVIM_APPNAME` is exported with that value before terminal launch, and Neovim uses `~/.config/<appname>/` for its configuration (D8)

3. **Given** `NA_NVIM_APPNAME` is set **When** the terminal subprocess inherits the environment **Then** only `NVIM_APPNAME` is affected — no other environment variables are modified

4. **And** the `config` reference file includes `NA_NVIM_APPNAME` with empty default
5. **And** the install script's example config includes `NA_NVIM_APPNAME` with descriptive comment
6. **And** `architecture.md` Config Variable Summary table includes `NA_NVIM_APPNAME`
7. **And** `architecture.md` Decision log includes D8 documenting the NVIM_APPNAME approach
8. **And** test coverage validates both empty and non-empty `NA_NVIM_APPNAME` behavior
9. **And** the main script stays within the 300-line budget (NFR12)
10. **And** the export line is placed immediately before the terminal launch command (init step 14)

## Tasks / Subtasks

- [x] Task 1: Add `NA_NVIM_APPNAME` default to main script (AC: #1, #9, #10)
  - [x] 1.1: Add `NA_NVIM_APPNAME=""` at line 42 (after `NA_FOCUS_DELAY="0.1"`) in Init Step 4 defaults block
  - [x] 1.2: Add conditional export before terminal launch: `[ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"` at line 143 (before `$NA_TERMINAL_CMD nvim ...`)

- [x] Task 2: Update `config` reference file (AC: #4)
  - [x] 2.1: Add `NA_NVIM_APPNAME=""` after `NA_FOCUS_DELAY="0.1"` (line 12)

- [x] Task 3: Update `install.sh` example config (AC: #5)
  - [x] 3.1: Add commented entry `# NA_NVIM_APPNAME=""` with descriptive comment `# Neovim APPNAME (uses ~/.config/<appname>/ for config, empty = normal config)` after the `NA_FOCUS_DELAY` block (before `CONFIGEOF` at line 75)

- [x] Task 4: Update `architecture.md` (AC: #6, #7)
  - [x] 4.1: Add row to Config Variable Summary table (after line 323): `| NA_NVIM_APPNAME | (empty) | Neovim APPNAME — uses ~/.config/<appname>/ for config |`
  - [x] 4.2: Add Decision D8 row to Decisions table (after D7 line 312): `| D8 | Neovim config isolation | NVIM_APPNAME env var via NA_NVIM_APPNAME | (empty) | Neovim 0.9+ natively supports NVIM_APPNAME. When set, Neovim reads ~/.config/<appname>/ instead of ~/.config/nvim/. Empty default = no change. Opt-in for minimal configs. |`

- [x] Task 5: Create tests `test/20_nvim_appname.bats` (AC: #1, #2, #3, #8)
  - [x] 5.1: Structural test: `NA_NVIM_APPNAME=` default exists in main script
  - [x] 5.2: Structural test: `NVIM_APPNAME` export line exists before terminal launch
  - [x] 5.3: Structural test: export is conditional on non-empty value (`[ -n`)
  - [x] 5.4: Functional test: when `NA_NVIM_APPNAME` is empty, `NVIM_APPNAME` is NOT in the environment passed to terminal
  - [x] 5.5: Functional test: when `NA_NVIM_APPNAME="always-nvim"`, `NVIM_APPNAME=always-nvim` IS exported
  - [x] 5.6: Structural test: `config` reference file contains `NA_NVIM_APPNAME`
  - [x] 5.7: Structural test: `install.sh` example config contains `NA_NVIM_APPNAME`
  - [x] 5.8: Run full test suite — 0 regressions

## Dev Notes

### CRITICAL: Line Budget

Current runtime: **271/300 lines** (29 remaining). This story adds **2 lines** to the main script:
1. `NA_NVIM_APPNAME=""` (default)
2. `[ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"` (conditional export)

Post-implementation: **273/300 lines** (27 remaining). Well within budget.

`config` and `install.sh` changes do NOT count against NFR12 (tooling/reference, not runtime).

### How NVIM_APPNAME Works (Neovim 0.9+)

Neovim checks the `NVIM_APPNAME` environment variable at startup. When set:
- Config loaded from `~/.config/$NVIM_APPNAME/` instead of `~/.config/nvim/`
- Data stored in `~/.local/share/$NVIM_APPNAME/` instead of `~/.local/share/nvim/`
- State stored in `~/.local/state/$NVIM_APPNAME/` instead of `~/.local/state/nvim/`
- Cache stored in `~/.cache/$NVIM_APPNAME/` instead of `~/.cache/nvim/`

When empty or unset, Neovim behaves normally. No special values needed — any non-empty string works.

### Exact Edit Locations in `always-nvim`

**Edit 1 — Init Step 4 (line 41-42):**
```bash
# CURRENT (line 41):
NA_FOCUS_DELAY="0.1"

# AFTER EDIT (lines 41-42):
NA_FOCUS_DELAY="0.1"
NA_NVIM_APPNAME=""
```

**Edit 2 — Init Step 14 (line 142-144):**
```bash
# CURRENT (lines 142-144):
# ── Init Step 14: Launch terminal + Neovim (blocks until exit) ───────────────
# shellcheck disable=SC2086
$NA_TERMINAL_CMD nvim "${nvim_args[@]}" "$tmpfile"

# AFTER EDIT (lines 142-145):
# ── Init Step 14: Launch terminal + Neovim (blocks until exit) ───────────────
[ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"
# shellcheck disable=SC2086
$NA_TERMINAL_CMD nvim "${nvim_args[@]}" "$tmpfile"
```

### Why `export` Before Terminal Launch (Not at Default Block)

The `export` must happen right before the terminal command because:
- `export` makes the variable available to child processes (the terminal + Neovim)
- Placing it at the default block would pollute the environment for ALL subprocesses throughout the script, not just Neovim
- Conditional export (`[ -n ... ] &&`) ensures it's only set when configured — preserving the zero-side-effect principle

### Testing Strategy

Test file: `test/20_nvim_appname.bats` (next available number after 19).

**Structural tests** use `grep` against `$SCRIPT_PATH` to verify code presence.

**Functional tests** for the export behavior: Use `bash -c` with `env` or `printenv` to check whether `NVIM_APPNAME` is exported. The script will fail at dependency check (step 8) when run with a fake HOME, but we can check if the export line works in isolation by sourcing the defaults block.

Pattern for functional test:
```bash
@test "nvim_appname: exports NVIM_APPNAME when NA_NVIM_APPNAME is set" {
  # Source just the defaults + config, then check env
  run bash -c '
    NA_NVIM_APPNAME="test-config"
    [ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"
    printenv NVIM_APPNAME
  '
  [ "$status" -eq 0 ]
  [ "$output" = "test-config" ]
}

@test "nvim_appname: does NOT export NVIM_APPNAME when NA_NVIM_APPNAME is empty" {
  run bash -c '
    NA_NVIM_APPNAME=""
    [ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"
    printenv NVIM_APPNAME
  '
  [ "$status" -ne 0 ]  # printenv returns 1 when var is not set
}
```

### Naming Conventions (MUST follow)

- Config variable: `NA_NVIM_APPNAME` (NA_ prefix, UPPER_SNAKE_CASE)
- Environment variable: `NVIM_APPNAME` (Neovim's native name — do NOT rename)
- Test file: `test/20_nvim_appname.bats`
- Test naming: `@test "nvim_appname: scenario description" { ... }`

### Anti-Patterns to AVOID

1. **DO NOT** export `NVIM_APPNAME` unconditionally — only when `NA_NVIM_APPNAME` is non-empty
2. **DO NOT** use `${NA_NVIM_APPNAME:-}` parameter expansion pattern — use direct assignment per project convention
3. **DO NOT** use the `function` keyword — use `name()` syntax
4. **DO NOT** add validation of the appname path — that's Neovim's responsibility
5. **DO NOT** create the `~/.config/<appname>/` directory — that's the user's responsibility
6. **DO NOT** modify any existing test files
7. **DO NOT** modify backend files — this is main script + config/docs only

### Project Structure Notes

- `always-nvim` — MODIFY: add default + conditional export (2 lines)
- `config` — MODIFY: add `NA_NVIM_APPNAME=""` (1 line)
- `install.sh` — MODIFY: add commented variable to example config (3 lines)
- `_bmad-output/planning-artifacts/architecture.md` — MODIFY: Config Variable Summary + Decision D8
- `test/20_nvim_appname.bats` — CREATE: NVIM_APPNAME tests
- `test/test_helper.bash` — DO NOT MODIFY
- `test/test_helper.sh` — DO NOT MODIFY
- All existing test files (01-19) — DO NOT MODIFY
- `backends/*.sh` — DO NOT MODIFY

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 4, Story 4.1] — Full acceptance criteria (lines 646-678)
- [Source: _bmad-output/planning-artifacts/epics.md#FR28] — Configurable options requirement (line 51)
- [Source: _bmad-output/planning-artifacts/architecture.md#Config Variable Summary] — Existing NA_* variables (lines 316-323)
- [Source: _bmad-output/planning-artifacts/architecture.md#Decisions] — D1-D7 decision table (lines 304-312)
- [Source: _bmad-output/planning-artifacts/architecture.md#Naming Conventions] — NA_ prefix pattern (lines 354-362)
- [Source: always-nvim lines 34-41] — Init Step 4 defaults block (edit location 1)
- [Source: always-nvim lines 142-144] — Init Step 14 terminal launch (edit location 2)
- [Source: config] — Reference config file (12 lines, append location)
- [Source: install.sh lines 51-75] — Example config heredoc (insert location)
- [Source: _bmad-output/implementation-artifacts/sprint-change-proposal-nvim-appname.md] — Approved change proposal

### Previous Story Intelligence (from Story 3.1)

- Agent model: claude-opus-4.6 (github-copilot)
- Test file naming: `NN_description.bats`, next available is `20`
- BATS executable: `./test/bats/bin/bats`
- `test_helper.bash` provides `PROJECT_ROOT`, `SCRIPT_PATH`, `SHELLTOOLSPATH` via `setup()`
- `test_helper.sh` provides mock backend functions (not needed for this story)
- Structural tests use `grep -q 'pattern' "$SCRIPT_PATH"` with status checks
- Functional tests use `run bash -c '...'` with inline setup and cleanup
- All **181 existing tests pass** (19 files), 0 regressions expected
- `install.sh` uses `set -e` — any edit must not break the heredoc or introduce errors
- Config test `04_config_parsing.bats` checks that all `NA_*` defaults are assigned — the new `NA_NVIM_APPNAME` MUST be added to the defaults block or test 04 may need updating (check after implementation)

## Dev Agent Record

### Agent Model Used

claude-opus-4.6 (github-copilot)

### Debug Log References

No issues encountered. Clean implementation — all changes applied on first attempt.

### Completion Notes List

- Task 1: Added `NA_NVIM_APPNAME=""` default at line 42, conditional export `[ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"` at line 143 (before terminal launch). Main script: 171 → 173 lines (273/300 budget).
- Task 2: Added `NA_NVIM_APPNAME=""` to `config` reference file after `NA_FOCUS_DELAY`.
- Task 3: Added commented `# NA_NVIM_APPNAME=""` with descriptive comment to `install.sh` heredoc before `CONFIGEOF`.
- Task 4: Added D8 decision row and `NA_NVIM_APPNAME` to Config Variable Summary in `architecture.md`.
- Task 5: Created `test/20_nvim_appname.bats` with 7 tests (3 structural, 2 functional, 2 config/install verification). Full suite: 188/188 pass, 0 regressions.

### File List

- `always-nvim` — MODIFIED: added NA_NVIM_APPNAME default (line 42) + conditional export (line 143)
- `config` — MODIFIED: added NA_NVIM_APPNAME="" (line 13)
- `install.sh` — MODIFIED: added commented NA_NVIM_APPNAME entry in example config heredoc (lines 76-77)
- `_bmad-output/planning-artifacts/architecture.md` — MODIFIED: added D8 decision + Config Variable Summary row
- `test/20_nvim_appname.bats` — CREATED: 7 NVIM_APPNAME tests
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED: story status transitions
- `_bmad-output/implementation-artifacts/4-1-nvim-appname-support.md` — MODIFIED: task checkboxes, dev agent record, status

### Change Log

- 2026-03-13: Implemented Story 4.1 NVIM_APPNAME support — 2 lines added to main script, config/install/architecture docs updated, 7 new tests (188 total, 0 regressions)
- 2026-03-13: Code review — fixed invalid NA_NVIM_APPNAME default in config reference (was "~/.config/always-nvim/nvim", corrected to ""). Accepted user's shellcheck improvements (SC2206 in always-nvim, SC2016 in install.sh).

## Senior Developer Review (AI)

**Review Date:** 2026-03-13
**Reviewer:** claude-opus-4.6 (github-copilot)
**Review Outcome:** Approve (after 1 fix)

### Findings Summary

- **1 HIGH** — `config` reference file had `NA_NVIM_APPNAME="~/.config/always-nvim/nvim"` instead of empty default. NVIM_APPNAME must be a simple name (no `/`). **FIXED** → set to `""`.
- **2 MEDIUM** — User added shellcheck directives (`SC2206` in always-nvim, `SC2016` in install.sh) not documented in story File List. These are valid improvements. **ACCEPTED** as-is.

### Action Items

- [x] Fix NA_NVIM_APPNAME default in config from path to empty string
- [x] Verify all 188 tests still pass after fix
