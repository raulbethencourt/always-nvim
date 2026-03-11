# Implementation Readiness Assessment Report

**Date:** 2026-03-10
**Project:** nvimAlways

---

## Step 1: Document Discovery

**stepsCompleted:** [step-01-document-discovery, step-02-prd-analysis, step-03-epic-coverage-validation, step-04-ux-alignment, step-05-epic-quality-review, step-06-final-assessment]

### Documents Identified for Assessment

| Document Type | File Path | Location Status |
|---|---|---|
| PRD | `_bmad-output/prd.md` | ⚠️ Outside planning-artifacts (root of _bmad-output) |
| Architecture | `_bmad-output/planning-artifacts/architecture.md` | ✅ Standard location |
| Epics & Stories | `_bmad-output/planning-artifacts/epics.md` | ✅ Standard location |
| UX Design | — | ❌ Not found |

### Issues Noted

- **PRD Location:** `prd.md` resides in `_bmad-output/` root rather than `planning-artifacts/`. Proceeding with this file.
- **UX Design Missing:** No UX/design document found. UX alignment checks will be limited.
- **No Duplicates:** No duplicate or sharded document conflicts detected.

### Files Included in Assessment

1. `_bmad-output/prd.md`
2. `_bmad-output/planning-artifacts/architecture.md`
3. `_bmad-output/planning-artifacts/epics.md`

---

## Step 2: PRD Analysis

### Functional Requirements (38 Total)

| ID | Category | Requirement |
|---|---|---|
| FR1 | Backend Detection | Detect X11 or Wayland via `$WAYLAND_DISPLAY` |
| FR2 | Backend Detection | Source correct backend module based on detected display server |
| FR3 | Backend Detection | Fail cleanly with descriptive error if backend dependencies missing |
| FR4 | Clipboard Mgmt | Save current system clipboard contents before operations |
| FR5 | Clipboard Mgmt | Restore saved clipboard after all operations complete |
| FR6 | Clipboard Mgmt | Restore clipboard on abort (`:q!` with empty/unchanged file) |
| FR7 | Clipboard Mgmt | Restore clipboard on signal interruption (SIGINT, SIGTERM) |
| FR8 | Clipboard Mgmt | Copy arbitrary text content to system clipboard |
| FR9 | Mode Detection | Read current primary selection |
| FR10 | Mode Detection | Determine Mode A (insert new) when primary selection empty |
| FR11 | Mode Detection | Determine Mode B (edit selection) when primary selection has text |
| FR12 | Temp File Mgmt | Create unique temporary file in configured temp directory |
| FR13 | Temp File Mgmt | Write captured selection text to temp file (Mode B) |
| FR14 | Temp File Mgmt | Read temp file contents after Neovim exits |
| FR15 | Temp File Mgmt | Detect abort conditions (empty or unchanged) |
| FR16 | Temp File Mgmt | Delete temp file on all exit paths |
| FR17 | Terminal/Editor | Spawn terminal emulator with window title `always-nvim` |
| FR18 | Terminal/Editor | Launch Neovim with temp file and configured filetype |
| FR19 | Terminal/Editor | Pass additional Neovim arguments from config |
| FR20 | Terminal/Editor | Block execution until terminal process exits |
| FR21 | Window Mgmt | Record focused window ID before spawning terminal |
| FR22 | Window Mgmt | Refocus recorded window after Neovim exits |
| FR23 | Window Mgmt | Wait configurable delay after refocus before paste |
| FR24 | Paste Simulation | Simulate Ctrl+V keystroke in focused application |
| FR25 | Paste Simulation | Wait configurable delay after paste before clipboard restore |
| FR26 | Configuration | Load shell-sourceable config from `~/.config/always-nvim/config` |
| FR27 | Configuration | Operate with sensible defaults when no config present |
| FR28 | Configuration | Support 9 configurable options (terminal, title flag, dimensions, filetype, nvim args, paste delay, focus delay, temp dir) |
| FR29 | Installation | Copy all script files to user-accessible location |
| FR30 | Installation | Create `~/.config/always-nvim/` directory and example config |
| FR31 | Installation | Display WM hotkey configuration snippets for i3 and Hyprland |
| FR32 | Backend Contract | `backend_get_selection()` — return selected text |
| FR33 | Backend Contract | `backend_copy_to_clipboard()` — copy stdin to clipboard |
| FR34 | Backend Contract | `backend_get_clipboard()` — return clipboard contents |
| FR35 | Backend Contract | `backend_set_clipboard()` — set clipboard from stdin |
| FR36 | Backend Contract | `backend_simulate_paste()` — simulate Ctrl+V |
| FR37 | Backend Contract | `backend_get_active_window()` — return focused window ID |
| FR38 | Backend Contract | `backend_refocus_window()` — refocus saved window |

### Non-Functional Requirements (14 Total)

| ID | Category | Requirement |
|---|---|---|
| NFR1 | Performance | Hotkey to Neovim ready < 500ms |
| NFR2 | Performance | Exit to text pasted < 300ms |
| NFR3 | Performance | Clipboard save/restore < 50ms each |
| NFR4 | Performance | Script memory < 50MB |
| NFR5 | Reliability | Clipboard restoration on 100% of invocations (all paths) |
| NFR6 | Reliability | Temp file cleanup on 100% of invocations including signals |
| NFR7 | Reliability | No orphan processes after any exit path |
| NFR8 | Reliability | Correct function after 100 consecutive invocations |
| NFR9 | Compatibility | X11 and Wayland identical from user perspective |
| NFR10 | Compatibility | Alacritty default, supports alternative terminals |
| NFR11 | Compatibility | Paste correctly into Chromium, Firefox, Slack, GTK/Qt |
| NFR12 | Maintainability | Codebase under 300 lines Bash (excl. comments/blanks) |
| NFR13 | Maintainability | Each backend under 50 lines Bash |
| NFR14 | Maintainability | New backend = new file only, no main script changes |

### Additional Requirements & Constraints

- Single-shot execution model (no daemon, no inter-run state)
- Linear flow: detect → save → spawn → wait → read → paste → restore → cleanup
- No backend fallback — clean failure if wrong backend loads
- Alacritty default terminal with `--title "always-nvim"` for WM matching
- `mktemp` for `/tmp/always-nvim-XXXXXX`; trap on EXIT, INT, TERM
- Config path: `~/.config/always-nvim/config` (9 options)
- Target: Regolith (i3/X11) and Omarchy (Hyprland/Wayland) only for MVP
- Estimated size: ~250 lines across 4 files

### PRD Completeness Assessment

PRD is well-structured and thorough. Requirements clearly numbered and traceable. Covers user journeys, configuration, backend contracts, installation, and both FR/NFR categories. Scope boundaries between MVP and post-MVP are cleanly delineated. Minor observation: `backend_copy_to_clipboard` (FR33) and `backend_set_clipboard` (FR35) both write to clipboard — roles should be validated against architecture doc.

---

## Step 3: Epic Coverage Validation

### Coverage Matrix

| PRD FR | Requirement Summary | Epic Coverage | Status |
|---|---|---|---|
| FR1 | Detect X11/Wayland | Epic 1, Story 1.1 | ✅ Covered |
| FR2 | Source correct backend | Epic 1, Story 1.1 | ✅ Covered |
| FR3 | Fail cleanly on missing deps | Epic 1, Stories 1.2 & 1.3 | ✅ Covered |
| FR4 | Save clipboard before ops | Epic 2, Story 2.4 | ✅ Covered |
| FR5 | Restore clipboard after ops | Epic 2, Story 2.4 / Epic 3, Story 3.1 | ✅ Covered |
| FR6 | Restore clipboard on abort | Epic 3, Story 3.1 | ✅ Covered |
| FR7 | Restore clipboard on signal | Epic 3, Story 3.1 | ✅ Covered |
| FR8 | Copy text to clipboard | Epic 2, Story 2.4 | ✅ Covered |
| FR9 | Read primary selection | Epic 2, Story 2.2 | ✅ Covered |
| FR10 | Mode A when empty selection | Epic 2, Story 2.2 | ✅ Covered |
| FR11 | Mode B when text selected | Epic 2, Story 2.2 | ✅ Covered |
| FR12 | Create unique temp file | Epic 2, Story 2.2 | ✅ Covered |
| FR13 | Write selection to temp (Mode B) | Epic 2, Story 2.2 | ✅ Covered |
| FR14 | Read temp file after exit | Epic 2, Story 2.4 | ✅ Covered |
| FR15 | Detect abort conditions | Epic 3, Story 3.2 | ✅ Covered |
| FR16 | Delete temp on all paths | Epic 3, Story 3.1 | ✅ Covered |
| FR17 | Spawn terminal with title | Epic 2, Story 2.3 | ✅ Covered |
| FR18 | Launch Neovim with filetype | Epic 2, Story 2.3 | ✅ Covered |
| FR19 | Pass additional nvim args | Epic 2, Stories 2.2 & 2.3 | ✅ Covered |
| FR20 | Block until terminal exits | Epic 2, Story 2.3 | ✅ Covered |
| FR21 | Record focused window | Epic 2, Story 2.4 | ✅ Covered |
| FR22 | Refocus window after exit | Epic 2, Story 2.4 | ✅ Covered |
| FR23 | Delay after refocus | Epic 2, Story 2.4 | ✅ Covered |
| FR24 | Simulate Ctrl+V paste | Epic 2, Story 2.4 | ✅ Covered |
| FR25 | Delay after paste | Epic 2, Story 2.4 | ✅ Covered |
| FR26 | Load config file | Epic 2, Story 2.1 | ✅ Covered |
| FR27 | Sensible defaults | Epic 2, Story 2.1 | ✅ Covered |
| FR28 | All options configurable | Epic 2, Story 2.1 | ✅ Covered |
| FR29 | Install copies files | Epic 4, Story 4.1 | ✅ Covered |
| FR30 | Install creates config dir | Epic 4, Story 4.1 | ✅ Covered |
| FR31 | Install shows WM snippets | Epic 4, Story 4.1 | ✅ Covered |
| FR32 | `backend_get_selection()` | Epic 1, Stories 1.2 & 1.3 | ✅ Covered |
| FR33 | `backend_copy_to_clipboard()` | Epic 1 (consolidated with FR35 into `backend_set_clipboard()` per ADC-1) | ✅ Covered (merged) |
| FR34 | `backend_get_clipboard()` | Epic 1, Stories 1.2 & 1.3 | ✅ Covered |
| FR35 | `backend_set_clipboard()` | Epic 1 (consolidated with FR33 per ADC-1) | ✅ Covered (merged) |
| FR36 | `backend_simulate_paste()` | Epic 1, Stories 1.2 & 1.3 | ✅ Covered |
| FR37 | `backend_get_active_window()` | Epic 1, Stories 1.2 & 1.3 | ✅ Covered |
| FR38 | `backend_refocus_window()` | Epic 1, Stories 1.2 & 1.3 | ✅ Covered |

### Missing Requirements

No PRD functional requirements are missing from epic coverage.

### Architecture-Driven Changes (Not Gaps)

1. **FR33+FR35 Consolidation (ADC-1):** Architecture merged `backend_copy_to_clipboard()` and `backend_set_clipboard()` into single `backend_set_clipboard()`. Epics correctly reflect 6-function contract. PRD still shows 7-function contract — should be updated for consistency.
2. **New FR38 Added by Architecture:** `--help`/`--version` flag handling (G4) added in Architecture, not in original PRD. Epics include it.
3. **NFR14 Updated:** Epics reference "6-function interface contract" vs PRD's "7-function." Reflects ADC-1.

### Coverage Statistics

- **Total PRD FRs:** 38
- **FRs covered in epics:** 38/38
- **Coverage percentage:** 100%
- **FR numbering divergence:** Yes — Epics renumbered FR33-FR38 to reflect Architecture consolidation. PRD retains original numbering.

---

## Step 4: UX Alignment Assessment

### UX Document Status

**Not Found** — No UX/design document exists in the project output.

### Assessment

A formal UX document is **not required** for this project. always-nvim is a stateless Bash automation script with no visual interface of its own. The tool's "UX" consists of:
1. Hotkey trigger (configured in WM, not the tool)
2. Floating window appearance (configured in WM rules, not the tool)
3. Neovim's editing experience (Neovim's responsibility)
4. Paste result (invisible — text appears in source app)

The PRD's User Journeys (1-4) and configuration options (terminal dimensions, delays, filetype) adequately capture user experience concerns. UX decisions are operational timing and mode detection behaviors, thoroughly covered in PRD and Architecture.

### Alignment Issues

None — no UX document exists and none is required for this CLI tool.

### Warnings

⚠️ **INFO (not blocking):** If future phases add GUI elements (e.g., desktop notifications via `notify-send`, filetype selection UI), a UX document should be created at that time.

---

## Step 5: Epic Quality Review

### Epic Structure Validation

#### User Value Focus

| Epic | Title | User Value? | Verdict |
|---|---|---|---|
| Epic 1 | Project Bootstrap & Backend Abstraction | 🔴 No — scaffolds and backend modules, no runnable tool | **VIOLATION** |
| Epic 2 | Core Editing Loop | ✅ Yes — complete hotkey-to-paste flow | **PASS** |
| Epic 3 | Safety, Cleanup & Abort Handling | 🟡 Borderline — technical title, implicit user value (zero side effects) | **BORDERLINE** |
| Epic 4 | Installation & Distribution | ✅ Yes — user goes from download to working setup | **PASS** |
| Epic 5 | Test Suite | 🔴 No — developer activity, no user value | **VIOLATION** |

#### Epic Independence

| Epic | Standalone? | Notes |
|---|---|---|
| Epic 1 | 🔴 FAIL | Creates scaffolds but no runnable flow — useless without Epic 2 |
| Epic 2 | ✅ PASS | Uses Epic 1 backends, builds complete editing loop |
| Epic 3 | ✅ PASS | Adds safety to Epic 2 flow (but see init ordering tension below) |
| Epic 4 | ✅ PASS | Copies files from prior epics |
| Epic 5 | ✅ PASS | Tests verify prior epics |

### Story Quality Assessment

All stories have strong Given/When/Then acceptance criteria, proper sizing, and no forward dependencies within or across epics. Highlights:

- **Stories 1.2 & 1.3:** Excellent backend contract coverage with V1-V4 normalization edge cases
- **Story 2.1:** Strong config/init coverage; notes external `.toolbox` dependency
- **Story 2.4:** Comprehensive paste flow with correct sequencing
- **Story 3.1:** Detailed two-phase trap architecture with idempotency requirement
- **Story 3.2:** Thorough abort/lock/stale-cleanup with `:cq` exit code handling (R5)

### Dependency Analysis

No forward dependencies detected. All story dependencies are within-epic and forward-only:
- Epic 1: 1.1 → 1.2, 1.3
- Epic 2: 2.1 → 2.2 → 2.3 → 2.4
- Epic 3: 3.1 → 3.2
- Epic 4: 4.1 standalone
- Epic 5: 5.1 → 5.2, 5.3, 5.4

### Quality Findings by Severity

#### 🔴 Critical Violations

**1. Epic 1 is a Technical Milestone (No User Value)**
- "Project Bootstrap & Backend Abstraction" delivers file scaffolds and backend implementations but no runnable tool.
- **Recommendation:** Merge into Epic 2 so first epic delivers a complete working flow, or restructure so Epic 1 delivers a minimal working flow on one backend.

**2. Epic 5 is a Technical Epic (Test Suite)**
- Testing is a developer activity, not user value.
- **Recommendation:** Integrate testing into each story's definition of done. Each story should include its own test coverage as part of acceptance criteria.

#### 🟠 Major Issues

**3. Epic 3 / Epic 2 Initialization Ordering Tension**
- Architecture's 14-step init order requires trap setup (Epic 3) at steps 5 and 10, before mode detection and terminal spawn (Epic 2 steps 12-14).
- **Recommendation:** Move Story 3.1 (Two-Phase Trap) into Epic 2 as an early story, or add a placeholder trap note to Epic 2 Story 2.1.

**4. Shell Library External Dependency (`$SHELLTOOLSPATH`)**
- Story 2.1 requires `.toolbox` from `$SHELLTOOLSPATH`. PRD states "Zero-dependency architecture: Pure Bash."
- **Recommendation:** Clarify in PRD or Architecture whether shell library is bundled or external. If external, list as dependency.

#### 🟡 Minor Concerns

**5. FR Numbering Divergence Between PRD and Epics**
- Epics renumbered FR33-FR38 for Architecture consolidation; PRD retains original numbering.
- Not blocking but creates cross-referencing confusion.

**6. Epic 3 Title Not User-Centric**
- "Safety, Cleanup & Abort Handling" reads as technical. Consider: "Zero Side Effects: Abort & Recovery."

---

## Summary and Recommendations

### Overall Readiness Status

**NEEDS WORK** — The planning artifacts are strong in substance but have structural issues in epic design that should be addressed before implementation begins.

### Strengths

- **100% FR coverage:** All 38 PRD functional requirements are traceable to specific epics and stories
- **Thorough acceptance criteria:** Every story uses proper Given/When/Then BDD format with testable, specific outcomes
- **Architecture integration:** Epics correctly incorporate Architecture Decisions (ADC-1 through ADC-7), risk mitigations (R1-R5), interface contract violations (V1-V4), and the critical 14-step initialization order
- **No forward dependencies:** Story ordering within and across epics is clean
- **PRD quality:** Well-structured, clearly scoped MVP with clean post-MVP boundaries
- **UX appropriateness:** Correctly no UX document for a CLI tool — not a gap

### Critical Issues Requiring Immediate Action

1. **Epic 1 delivers no user value** — It's a pure scaffolding/technical epic. Merge it into Epic 2 or restructure so the first epic delivers a minimal working flow.
2. **Epic 5 (Test Suite) is a technical epic** — Testing should be part of each story's definition of done, not a standalone epic with no user value.

### Recommended Next Steps

1. **Restructure Epic 1 + Epic 2:** Merge backend creation into the core editing loop epic so the first deliverable is a working tool on at least one backend. Consider: Epic 1 = "Full editing loop on X11", then a later story or epic adds Wayland parity.
2. **Distribute Epic 5 test stories:** Move each test story into the epic it verifies (e.g., Story 5.1 backend contract tests → Epic 1, Story 5.2 mode detection tests → Epic 2, etc.), or add testing as acceptance criteria within each existing story.
3. **Resolve Epic 3 / Epic 2 init ordering tension:** Either move Story 3.1 (Two-Phase Trap) into Epic 2 as an early story, or add explicit guidance to Epic 2 Story 2.1 that a basic `trap cleanup EXIT` placeholder is needed until the full two-phase trap is implemented.
4. **Clarify shell library dependency:** The `$SHELLTOOLSPATH` / `.toolbox` requirement in Story 2.1 contradicts the PRD's "zero-dependency" claim. Update PRD to list it as a prerequisite, or bundle it.
5. **Align FR numbering:** Update the PRD to reflect the Architecture's FR33+FR35 consolidation (ADC-1) so all three documents (PRD, Architecture, Epics) use consistent FR numbers.
6. **(Optional) Rename Epic 3:** Make the title more user-centric — e.g., "Zero Side Effects: Abort & Recovery."

### Issue Summary

| Severity | Count | Description |
|---|---|---|
| 🔴 Critical | 2 | Epic 1 no user value; Epic 5 technical epic |
| 🟠 Major | 2 | Init ordering tension; shell library dependency unclear |
| 🟡 Minor | 2 | FR numbering divergence; Epic 3 title |
| Total | 6 | |

### Final Note

This assessment identified **6 issues across 3 severity levels**. The project's planning substance is solid — requirements are complete, acceptance criteria are thorough, and the architecture is well-integrated into the stories. The issues are structural (epic design) and documentation consistency (FR numbering, dependency listing), not gaps in coverage or logic. Address the 2 critical issues before proceeding to implementation; the remaining 4 can be resolved during implementation or accepted as-is.

**Assessor:** Winston (Architect Agent)
**Date:** 2026-03-10
