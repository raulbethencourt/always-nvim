# Sprint Change Proposal: Library Dead Code Removal

**Date:** 2026-03-13
**Triggered by:** Post-sprint code quality review (Maestro)
**Status:** Pending Approval
**Scope:** Minor

---

## Section 1: Issue Summary

The `lib/` shell library ships ~1,187 lines across 6 modules, but the always-nvim project only uses a subset at runtime. Approximately 380-390 lines are dead code — functions, constants, and entire modules never called by `always-nvim`, `install.sh`, or any transitive dependency chain. This includes `validation.sh` (166 lines, 100% unused) and `utils.sh` (empty file, 0 lines).

**Discovery context:** Post-sprint review after all 4 epics (12 stories, 188 tests) were completed. A comprehensive function-level usage audit was performed, mapping every function call in the project runtime to its source in the library.

**Evidence:** Complete usage audit identifying every used and unused function across all 6 library modules, including transitive dependency chains (e.g., `parse_options` → `toolbox_print_usage` → usage printing functions in `ui.sh`).

## Section 2: Impact Analysis

### Epic Impact
None. All 4 epics are done. No epic scope, priority, or structure changes required. This is a post-sprint maintenance task outside the epic framework.

### Story Impact
No existing stories affected. No new stories required.

### Artifact Conflicts
- **PRD:** No conflicts. The PRD doesn't specify library internals.
- **Architecture:** Minor documentation updates needed — 3 project structure diagrams and ADC-5 line count reference.
- **UI/UX:** N/A (CLI tool, no visual design docs).

### Technical Impact
- **6 library files** modified or deleted
- **1 documentation file** deleted (`docs/lib_example_script.sh`)
- **1 planning artifact** updated (`architecture.md`)
- **NFR12 (300-line budget):** Unaffected — `lib/` is excluded from the runtime budget
- **Runtime behavior:** Zero changes — only unused code is removed

## Section 3: Recommended Approach

**Direct Adjustment** — targeted removal of dead code from library files, deletion of entirely unused modules, and documentation updates. No structural changes, no new files, no new dependencies.

- **Effort:** Low — well-scoped subtractive changes with complete audit already done
- **Risk:** Low — 188 BATS tests serve as comprehensive regression safety net
- **Timeline impact:** None — all epics complete, no blocking dependencies

**Alternatives considered:**
- *Do nothing:* Safe but leaves acknowledged tech debt. Rejected — Maestro explicitly wants this cleaned.
- *Partial removal (delete files only):* Removes `validation.sh` and `utils.sh` but leaves dead functions in other modules. Rejected — incomplete cleanup.
- *Full pruning (selected):* Maximum cleanup with conservative approach on tightly-coupled modules (`options.sh`). Mitigated by thorough audit + 188 tests.

## Section 4: Detailed Change Proposals

### Proposal 1: Delete `lib/validation.sh`
**Action:** Delete entire file (166 lines)
**Rationale:** Zero functions used by the project. 100% dead code. Functions: `validint`, `validfloat`, `exceed_days_in_month`, `is_leap_year`, `valid_alpha_num`, `month_num_to_name`, `nicenumber`.

### Proposal 2: Delete `lib/utils.sh`
**Action:** Delete entire file (0 lines — empty)
**Rationale:** Empty file, provides nothing. Removing eliminates a useless source operation in `.toolbox`.

### Proposal 3: Delete `docs/lib_example_script.sh`
**Action:** Delete entire file (69 lines)
**Rationale:** Uses functions being removed (`get_file_with_fzf`, `get_env_file_from_path`). Demonstrates the original library, not always-nvim. Maestro confirmed deletion.

### Proposal 4: Update `lib/.toolbox`
**Action:** Remove sourcing of `validation.sh` and `utils.sh`, update module list comments.
**Before:** 6 modules sourced, comments list 6 modules.
**After:** 4 modules sourced (`core.sh`, `file.sh`, `options.sh`, `ui.sh`), comments updated.

### Proposal 5: Prune `lib/core.sh`
**Action:** Remove 13 dead functions (~135 lines)
**Remove:** `return_error`, `error_usage`, `redirect_to_log`, `set_log_category`, `sanitize_filename`, `ensure_output_dir`, `normalize`, `make_unique`, `not`, `is_default`, `is_empty`, `or_condition`, `print_env`
**Keep:** `echo_error`, `error_exit`, logging config exports, `toolbox_log`, `echo` override
**Result:** 182 lines → ~47 lines

### Proposal 6: Prune `lib/file.sh`
**Action:** Remove 3 dead functions (~54 lines)
**Remove:** `echo_n`, `get_file_with_fzf`, `get_env_file_from_path`
**Keep:** `in_path`, `check_for_cmd_in_path`
**Result:** 89 lines → ~35 lines

### Proposal 7: Prune `lib/options.sh`
**Action:** Remove 4 dead functions (~40 lines)
**Remove:** `def_pos_arg`, `option_print_argument`, `parse_partial_options`, `option_print_short`
**Keep:** All functions in the `parse_options` → `_parse_options_impl` dependency chain
**Result:** 543 lines → ~503 lines

### Proposal 8: Prune `lib/ui.sh`
**Action:** Remove `print_progress()` function only (~30 lines)
**Keep:** All color constants (foreground + background), all text formatting constants, `RESET`, `printcn`, and all usage printing functions
**Rationale:** Colors and formatting constants are cheap to keep and useful for future work. Only the `print_progress()` function is confirmed dead.
**Result:** 207 lines → ~177 lines

### Proposal 9: Update `architecture.md`
**Action:** Update 3 project structure diagrams to remove `utils.sh`, `validation.sh`, and `docs/` directory. Update ADC-5 line count from "under 1,200 lines" to "under 800 lines". Update `lib/` description to "pruned to project needs".

## Section 5: Implementation Handoff

- **Change scope:** Minor — direct implementation by dev team
- **Recipient:** Dev agent (Amelia)
- **Responsibilities:**
  1. Execute all 9 proposals (file deletions, function removals, doc updates)
  2. Run full test suite (188 BATS tests) — verify zero regressions
  3. Verify `always-nvim --help` and `always-nvim --version` still work (transitive `parse_options` chain intact)
- **Success criteria:**
  - All 188 tests pass
  - `always-nvim --help` prints usage correctly
  - `always-nvim --version` prints version correctly
  - No runtime behavior changes
  - Architecture doc accurately reflects post-pruning structure

## Summary

| Metric | Before | After |
|--------|--------|-------|
| Library modules | 6 files | 4 files |
| Total library lines (approx) | ~1,187 | ~762 |
| Dead code removed | — | ~390 lines |
| Files deleted | — | 4 (`validation.sh`, `utils.sh`, `lib_example_script.sh`, `docs/` dir) |
| Tests affected | — | 0 (all 188 pass) |
| Runtime behavior changes | — | None |
