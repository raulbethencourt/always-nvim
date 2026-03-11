# Epic 1 Retrospective: Core Editing Loop

**Date:** 2026-03-11
**Epic:** Epic 1 — Core Editing Loop
**Stories:** 7 (1.1 through 1.7)
**Agent:** claude-opus-4.6 (github-copilot) — all stories
**Maestro:** Rabeta

---

## Delivery Summary

| Metric | Value |
|--------|-------|
| Stories completed | 7/7 |
| Source lines (non-test) | 263 (always-nvim: 163, x11.sh: 46, wayland.sh: 54) |
| Test files | 15 (.bats) + 2 helpers |
| Test count | 117/117 passing |
| Test lines | 1,675 |
| Test:source ratio | 6.4:1 |
| Contract violations covered | V1, V2, V3, V4 |
| Architecture decisions honored | ADC-1, ADC-2, ADC-7 |

---

## What Went Well

### 1. Test-first discipline held across all stories
Every story had tests passing before being marked complete. The suite grew monotonically: 40 → 54 → 67 → 72 → 87 → 117. Zero regressions at any point. The 6.4:1 test-to-source line ratio reflects thorough coverage for a Bash tool.

### 2. Contract violations (V1-V4) caught and normalized cleanly
The architecture spec identified Wayland divergences early. V1/V2 (exit code normalization), V3 (`printf '%s'` over `echo`), and V4 (null/zero hyprctl address) were all implemented correctly on first pass in Story 1.3 and regression-tested in Story 1.7.

### 3. Backend interface contract (ADC-1) proved stable
The 6-function interface (`get_selection`, `get_clipboard`, `set_clipboard`, `simulate_paste`, `get_active_window`, `refocus_window`) never changed after being defined. Both backends implement it in under 50 lines. NFR14 (new backend = new file, no main script changes) is satisfied by design.

### 4. Story sequencing was well-ordered
Each story built cleanly on the previous one's output. Init steps 1-14 were implemented in logical order. Placeholders (steps 9-11) were correctly deferred to later stories without blocking progress.

### 5. Code review feedback (Story 1.1) improved quality early
The post-implementation review that removed `SHELLTOOLSPATH`, adopted `parse_options`, and renamed `VERSION` to `NA_VERSION_TO_SHOW` cleaned up the foundation before 6 more stories built on it.

---

## What Could Be Improved

### 1. Story 1.1 test migration was messy
Story 1.1 initially used plain shell test files (`test_0N_*.sh`), which were later converted to BATS `.bats` files. The naming convention and test runner approach should have been locked down in the architecture before implementation started. This caused rework.

### 2. Story 1.2 Dev Agent Record is sparse
Unlike all other stories, 1.2 has no explicit agent model recorded and minimal completion notes. This makes it harder to trace decisions. All stories should have uniform record-keeping.

### 3. Centralized mock helper (ADC-7) came late
`test/test_helper.sh` was created in Story 1.7 — the *last* story. Stories 1.2-1.6 all used inline mock approaches (temp directory with mock executables, subshell function overrides). While these work, having the centralized helper earlier would have reduced boilerplate. Future epics should front-load test infrastructure stories.

### 4. File-based mock capture was a late discovery
The pipe-subshell problem (variable assignments in piped commands don't propagate) was discovered during Story 1.7 implementation. This is a well-known Bash gotcha. The centralized mock helper had to use `MOCK_STATE_DIR` with file-based capture. This pattern should be documented as a team standard for future Bash test development.

### 5. R1 backup file tests are specification-only
AC #12 in Story 1.7 tests the backup file pattern in isolation, but the mechanism isn't wired into `always-nvim` yet (that's Story 2.1). These tests verify the *concept* works but can't verify the integration until Epic 2.

---

## Patterns Established (carry forward to Epic 2)

| Pattern | Description | Used In |
|---------|-------------|---------|
| Inline mock executables | Temp dir with mock scripts on PATH, `source` backend, test functions | Stories 1.2, 1.3, 1.7 (contract tests) |
| Extracted-logic subshell | `bash -c "..."` with function overrides to test script logic in isolation | Stories 1.4, 1.6, 1.7 (mode detection, paste flow, clipboard cycle) |
| Structural grep | `grep -q 'pattern' "$SCRIPT_PATH"` for verifying code patterns exist | Stories 1.1-1.6 |
| Centralized mock helper | `source test/test_helper.sh` — file-based capture, `mock_reset()` | Story 1.7 (ADC-7) |
| `printf '%s'` everywhere | Never `echo` for data — prevents V3 trailing newline corruption | All stories |

---

## Risks & Debt Carried into Epic 2

1. **No cleanup/trap coverage yet** — `always-nvim` currently has only a minimal `EXIT` trap for lock file. Story 2.1 (Two-Phase Trap & Cleanup) and 2.2 (Abort Detection, Lock File, Stale Cleanup) must implement proper signal handling. The R1 backup file specification tests from Story 1.7 will serve as integration targets.

2. **No abort detection** — FR15 (empty/unchanged temp file = abort) is not yet implemented. Story 2.2 handles this.

3. **Lock file is placeholder** — Current `echo $$ > "$LOCK_FILE"` with basic EXIT trap doesn't handle stale locks, concurrent instances, or proper PID validation.

4. **Primary selection clear (`NA_CLEAR_PRIMARY`)** — Config variable exists but no code uses it yet. Not in any Epic 2 story — may need a story or be deferred.

---

## Metrics for Epic 2 Planning

- **Average story size:** ~37 source lines + ~24 test lines per story (excluding 1.7 test-only)
- **Agent model consistency:** claude-opus-4.6 worked well across all stories — no model-related issues
- **Test execution time:** Full suite (117 tests) runs in ~2-3 seconds — no performance concerns
- **Codebase health:** 263 source lines vs 300-line budget (NFR12) — 37 lines remaining for Epic 2+3

---

## Recommendation

Epic 1 delivered a complete, tested core editing loop. The architecture held, contract violations are covered, and test infrastructure is mature. Proceed to **Epic 2: Robustness & Cleanup** with confidence.

Consider front-loading Story 2.1 (trap system) since it's the foundation for all cleanup behavior, and the specification tests from Story 1.7 already define the expected contract.
