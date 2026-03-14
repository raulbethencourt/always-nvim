# Combined Retrospective: Epics 2, 3 & 4

**Date:** 2026-03-13
**Epics:** Epic 2 (Zero Side Effects), Epic 3 (Installation), Epic 4 (Enhanced Neovim Config)
**Stories:** 5 (2.1, 2.2, 2.3, 3.1, 4.1)
**Agent:** claude-opus-4.6 (github-copilot) — all stories
**Maestro:** Rabeta

---

## Delivery Summary

| Metric | Value |
|--------|-------|
| Stories completed | 5/5 |
| Runtime source lines added | +10 (163 -> 173) |
| Tests added | 71 (117 -> 188) |
| Test files added | 5 (15 -> 20) |
| Final runtime budget | 273/300 (27 remaining) |
| Install script | ~85 lines (tooling, not counted) |
| Regressions | 0 |
| Code review issues caught | ~7 across all stories |

---

## Epic 2: Zero Side Effects (Stories 2.1, 2.2, 2.3)

| Story | What Shipped | Source delta | Tests |
|-------|-------------|-------------|-------|
| 2.1 Two-Phase Trap & Cleanup | cleanup() function, trap upgrade, R1 backup | +5 | 12 |
| 2.2 Abort Detection, Lock & Stale | Lock with PID, stale cleanup, no-change detection | +3 | 14 |
| 2.3 Cleanup & Trap Tests | Test-only story — comprehensive trap/lock/stale tests | 0 | 19 |

**Net runtime lines:** +8 for an entire safety system. Budget discipline was exceptional.

## Epic 3: Installation (Story 3.1)

| Story | What Shipped | Source delta | Tests |
|-------|-------------|-------------|-------|
| 3.1 Install Script | install.sh (~85 lines), config gen, WM snippets | 0 (tooling) | 18 |

**Net runtime lines:** 0 — install.sh is tooling, not counted against NFR12.

## Epic 4: Enhanced Neovim Config (Story 4.1)

| Story | What Shipped | Source delta | Tests |
|-------|-------------|-------------|-------|
| 4.1 NVIM_APPNAME | Conditional export before terminal launch | +2 | 7 |

**Net runtime lines:** +2. Cleanest story in the project — first-pass success, zero debug issues.

---

## Epic 1 Debt Resolution

| Epic 1 Risk/Debt | Resolution |
|-------------------|-----------|
| No cleanup/trap coverage | Resolved — Story 2.1 two-phase trap + Story 2.3 (19 tests) |
| No abort detection (FR15) | Resolved — Story 2.2 :cq detection + no-change detection |
| Lock file is placeholder | Resolved — Story 2.2 PID validation + stale lock removal |
| Primary selection clear (NA_CLEAR_PRIMARY) | Still deferred — config var exists, no backend function |

## Epic 1 Patterns Carried Forward

All 5 patterns from Epic 1 retro were used successfully in Epics 2-4:
- Inline mock executables
- Extracted-logic subshell (bash -c)
- Structural grep
- Centralized mock helper (test_helper.sh)
- printf '%s' everywhere (zero V3 violations)

---

## What Went Well

### 1. Budget discipline was exceptional
Epic 2 added only 8 source lines for an entire safety system (trap + lock + abort + stale cleanup). Epic 4 added just 2. Total project: 173/300 lines with 127 lines of headroom.

### 2. Test-first held strong across all epics
Test count grew monotonically: 117 -> 129 -> 143 -> 163 -> 181 -> 188. Zero regressions at any point.

### 3. Story 2.3 (test-only story) was the right call
Dedicating a full story to 19 deep cleanup/trap tests gave proper attention to edge cases: idempotent cleanup, trap ordering, stale aging, lock scenarios.

### 4. Code review caught real issues every time
Lock file without $EUID, unsafe find glob (2.2), missing set -e, PATH check logic (3.1), invalid config default (4.1). The review step paid for itself.

### 5. Lib pruning sprint cleaned up ~285 lines of dead code
Removed 2 entire modules (validation.sh, utils.sh), trimmed 3 others, cleaned architecture docs. Clean codebase going forward.

### 6. Story 4.1 proved architecture quality
2 lines, first-pass success, no debug issues. A well-architected codebase makes new features trivial to add.

---

## What Could Be Improved

### 1. Primary selection clear is still deferred
NA_CLEAR_PRIMARY config variable exists since Story 1.1 but there's no backend function to clear primary selection. Minor UX debt.

### 2. lib/ modules were over-scoped initially
validation.sh and utils.sh were never needed by this project. The pruning sprint cleaned them up, but ideally the toolbox would have been scoped tighter from the start.

### 3. Epic 3 and 4 were very small
One story each. Could have been combined into a single "Polish" epic. The epic granularity felt slightly heavy for these.

---

## Remaining Debt

| Item | Status | Priority |
|------|--------|----------|
| NA_CLEAR_PRIMARY — no backend function | Deferred | Low |
| No E2E/integration tests | By design | Low |

---

## Project Final Scorecard

| Metric | Value |
|--------|-------|
| Epics completed | 4/4 |
| Stories completed | 12/12 |
| Total tests | 188 (all passing) |
| Runtime source lines | 173/300 (57.7% of budget) |
| Headroom remaining | 127 lines |
| Test files | 20 (.bats) + 2 helpers |
| Contract violations covered | V1, V2, V3, V4 |
| Lib pruning | ~285 lines removed |
| Regressions across all epics | 0 |
