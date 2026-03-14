# Sprint Change Proposal: Post-Deployment Bug Fixes & Tech Debt Resolution

**Date:** 2026-03-14
**Triggered by:** Live debugging session — real-world usage on Regolith 3 (i3/X11) revealed 1 critical bug, 1 unimplemented feature, and 1 UX improvement
**Status:** Approved
**Scope:** Minor

---

## Section 1: Issue Summary

Three issues were discovered during the first real-world deployment and debugging session on Maestro's Regolith 3 desktop (i3-based, X11, French AZERTY keyboard). All three have already been **fixed in code** and all 188 tests pass with zero regressions. This proposal formalizes the changes into the project's planning artifacts.

### Change 1: SCRIPT_DIR Symlink Resolution (Critical Bug)

The `SCRIPT_DIR` computation used `$(cd "$(dirname "$0")" && pwd)`, which resolves to the **symlink's directory** (`/usr/local/bin/`) rather than the **target's directory** (`~/.local/bin/`). Since `install.sh` creates a symlink at `/usr/local/bin/always-nvim → ~/.local/bin/always-nvim`, and i3's `exec` uses `/usr/local/bin/` (which is in `$PATH`), the script failed every time it was invoked via hotkey — `source "$SCRIPT_DIR/lib/.toolbox"` pointed to a nonexistent path.

**Fix:** `SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"`

### Change 2: ADC-4 Primary Selection Clearing (Tech Debt Completed)

ADC-4 defined `NA_CLEAR_PRIMARY` as a configurable option to clear the primary selection after each invocation, preventing stale selections from triggering unintended Mode B. The config variable existed since Story 1.1, the architecture decision was documented, but the **backend function was never created and the wiring was never done**. This was tracked as tech debt in both the Epic 1 and Epic 2-3-4 retrospectives.

**Fix:** Added `backend_clear_primary()` to both backends (x11: `xclip -selection primary -i`, wayland: `wl-copy --primary`), wired into main script at Step 12 after `backend_get_selection`.

### Change 3: Terminal `--class` Flag for WM Window Matching (UX Improvement)

The default `NA_TERMINAL_CMD` used only `--title always-nvim` for WM matching. In practice, `for_window [title="always-nvim"]` in i3 was too broad — it matched any window whose title contained "always-nvim" (e.g., a terminal editing the project source). Maestro requested matching on `class` instead, which is set exclusively by the terminal's `--class` flag.

**Fix:** Default changed from `alacritty --title always-nvim -e` to `alacritty --class always-nvim --title always-nvim -e`. The `--title` is preserved for backward compatibility.

## Section 2: Impact Analysis

### Epic Impact
None. All epics (1-5) retain their current status. No epic scope, priority, or structure changes. These are retroactive corrections to already-completed work.

### Story Impact
No new stories required. Acceptance criteria text updates needed in:
- **Story 1.1** (2 corrections: SCRIPT_DIR pattern, NA_TERMINAL_CMD default)
- **Story 1.5** (1 correction: WM matching mechanism description)

### Artifact Conflicts

| Artifact | Conflict | Severity |
|----------|----------|----------|
| `epics.md` — Story 1.1 AC | SCRIPT_DIR pattern incorrect; NA_TERMINAL_CMD default outdated | Low |
| `epics.md` — Story 1.5 AC | Says "rules match on the title string" — now class | Low |
| `architecture.md` — ADC-1 | Says "6 functions" — now 6 core + 1 auxiliary (`backend_clear_primary`) | Low |
| `architecture.md` — D5 | NA_TERMINAL_CMD template missing `--class` | Low |
| `architecture.md` — Config table | NA_TERMINAL_CMD default outdated | Low |
| `architecture.md` — NFR13 | 50-line backend budget — x11.sh now 51 lines, wayland.sh now 59 lines | Low |
| `install.sh` — example config | NA_TERMINAL_CMD example missing `--class` | Low |
| `install.sh` — WM snippets | i3 snippet uses `title=` instead of `class=` | Low |
| `README.md` — config table | NA_TERMINAL_CMD default outdated | Low |
| `README.md` — WM examples | i3 example uses `title=` matching | Low |

### Technical Impact
- **Code:** 3 files modified (`always-nvim`, `backends/x11.sh`, `backends/wayland.sh`) — all changes already implemented
- **Tests:** 1 test updated (`02_init_steps.bats` test 10) — all 188 tests pass
- **NFR12 (300-line budget):** `always-nvim` at 175 lines — well within budget
- **NFR13 (50-line backend budget):** Slightly exceeded (51 and 59 lines) due to `backend_clear_primary()`
- **Runtime behavior:** All three changes improve correctness/UX, no regressions

## Section 3: Recommended Approach

**Direct Adjustment** — update planning artifacts to reflect the already-implemented code changes. No structural changes, no new stories, no epic restructuring.

- **Effort:** Medium (many artifact files to update, but all are simple text replacements)
- **Risk:** Low (code is done and tested; these are documentation corrections)
- **Timeline impact:** None (all code work is complete)

**Alternatives considered:**
- *Do nothing:* Leaves artifacts inaccurate. Rejected — artifacts should match implementation.
- *Create new stories:* Overkill for retroactive documentation fixes. Rejected.
- *Raise NFR13 to 60 lines:* Recommended as part of the architecture update to formally accept the backend size increase.

## Section 4: Detailed Change Proposals

### Proposal 1: `epics.md` — Story 1.1 SCRIPT_DIR Pattern

**Story:** 1.1 — Project Structure, Configuration & Backend Detection
**Section:** Acceptance Criteria (SCRIPT_DIR resolution)

OLD:
```
resolves SCRIPT_DIR via symlink-safe $(cd "$(dirname "$0")" && pwd)
```

NEW:
```
resolves SCRIPT_DIR via symlink-safe $(cd "$(dirname "$(readlink -f "$0")")" && pwd)
```

**Rationale:** The old pattern is not symlink-safe. `readlink -f` resolves the full symlink chain before extracting the directory.

### Proposal 2: `epics.md` — Story 1.1 NA_TERMINAL_CMD Default

**Story:** 1.1 — Project Structure, Configuration & Backend Detection
**Section:** Acceptance Criteria (defaults)

OLD:
```
NA_TERMINAL_CMD="alacritty --title always-nvim -e"
```

NEW:
```
NA_TERMINAL_CMD="alacritty --class always-nvim --title always-nvim -e"
```

**Rationale:** `--class` enables precise WM window matching via `class=` rules. `--title` preserved for compatibility.

### Proposal 3: `epics.md` — Story 1.5 WM Matching

**Story:** 1.5 — Terminal Spawn & Neovim Orchestration
**Section:** Acceptance Criteria

OLD:
```
configured floating/sizing rules match on the title string
```

NEW:
```
configured floating/sizing rules match on the window class (preferred) or title string
```

**Rationale:** Class matching is more precise than title matching in practice.

### Proposal 4: `architecture.md` — ADC-1 Interface Count

**Section:** ADC-1: Backend Interface — 6 Functions (Consolidated)

OLD:
```
Revised interface: backend_get_selection(), backend_get_clipboard(), backend_set_clipboard(),
backend_simulate_paste(), backend_get_active_window(), backend_refocus_window().
```

NEW:
```
Core interface (6 functions): backend_get_selection(), backend_get_clipboard(),
backend_set_clipboard(), backend_simulate_paste(), backend_get_active_window(),
backend_refocus_window().
Auxiliary (1 optional function): backend_clear_primary() — clears primary selection (ADC-4).
```

**Rationale:** `backend_clear_primary` is not part of the core contract (new backends can omit it) but should be documented.

### Proposal 5: `architecture.md` — D5 Terminal Command Template

**Section:** Decision Log — D5

OLD:
```
alacritty --title always-nvim -e
```

NEW:
```
alacritty --class always-nvim --title always-nvim -e
```

**Rationale:** Reflects the actual default. Apply this same replacement to the Config Variable Summary table and pseudocode sections.

### Proposal 6: `architecture.md` — NFR13 Backend Line Budget

**Section:** Non-Functional Requirements

OLD:
```
NFR13: Each backend module shall remain under 50 lines of Bash
```

NEW:
```
NFR13: Each backend module shall remain under 60 lines of Bash
```

**Rationale:** Addition of `backend_clear_primary()` (~4 lines) to each backend pushes x11.sh to 51 and wayland.sh to 59. Raising the budget to 60 formalizes the accepted variance. The backends remain compact and focused.

### Proposal 7: `install.sh` — Example Config and WM Snippets

**Section:** Example config line

OLD:
```bash
# NA_TERMINAL_CMD="alacritty --title always-nvim -e"
```

NEW:
```bash
# NA_TERMINAL_CMD="alacritty --class always-nvim --title always-nvim -e"
```

**Section:** i3 WM snippet

OLD:
```
for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center
```

NEW:
```
for_window [class="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center
```

**Rationale:** Match the actual recommended configuration. Class matching is more precise.

### Proposal 8: `README.md` — Config Table and WM Examples

**Section:** Configuration table — NA_TERMINAL_CMD default

OLD:
```
| `NA_TERMINAL_CMD` | `alacritty --title always-nvim -e` | Terminal command to launch... |
```

NEW:
```
| `NA_TERMINAL_CMD` | `alacritty --class always-nvim --title always-nvim -e` | Terminal command to launch... |
```

**Section:** i3 WM keybinding example — update `for_window` rule from `title=` to `class=`.

**Rationale:** README must match the actual defaults and recommended configuration.

## Section 5: Implementation Handoff

- **Change scope:** Minor — direct implementation by dev team
- **Recipient:** Dev agent
- **Responsibilities:**
  1. Execute Proposals 1-3 (update `epics.md` — 3 text corrections)
  2. Execute Proposals 4-6 (update `architecture.md` — ADC-1, D5, config table, NFR13, pseudocode)
  3. Execute Proposal 7 (update `install.sh` — example config + i3 WM snippet)
  4. Execute Proposal 8 (update `README.md` — config table + WM examples)
  5. Run full test suite — verify all 188 tests still pass
- **Success criteria:**
  - All 188 tests pass
  - All `NA_TERMINAL_CMD` default references across artifacts show `alacritty --class always-nvim --title always-nvim -e`
  - All i3 WM rule examples use `class=` instead of `title=`
  - ADC-1 documents the auxiliary `backend_clear_primary()` function
  - NFR13 reflects the 60-line backend budget
  - Story 1.1 AC shows `readlink -f` pattern for SCRIPT_DIR
