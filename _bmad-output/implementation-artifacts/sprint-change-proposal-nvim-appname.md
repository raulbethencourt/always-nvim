# Sprint Change Proposal: NVIM_APPNAME Support

**Date:** 2026-03-13
**Trigger:** Post-MVP feature request (Maestro)
**Change Scope:** Minor — Direct implementation by dev team
**Status:** Approved

---

## Section 1: Issue Summary

Users with complex Neovim configurations experience slow startup and irrelevant plugin loading when using always-nvim for quick edits. Neovim 0.9+ natively supports the `NVIM_APPNAME` environment variable, which redirects config lookup from `~/.config/nvim/` to `~/.config/<appname>/`. Adding a `NA_NVIM_APPNAME` config variable allows users to opt into a dedicated, minimal Neovim config for always-nvim.

**Discovery context:** All 3 original epics (11 stories, 181 tests) are complete. This is an additive post-MVP enhancement identified by the project owner.

---

## Section 2: Impact Analysis

### Epic Impact
- **Epics 1-3:** No changes needed — all complete and unaffected.
- **New Epic 4:** "Enhanced Neovim Configuration" with one story (4.1: NVIM_APPNAME Support).

### Story Impact
- No existing stories modified.
- One new story: Story 4.1.

### Artifact Conflicts
- **PRD:** No conflict. MVP fully delivered. This is a post-MVP enhancement.
- **Architecture (`architecture.md`):** Minor update — add `NA_NVIM_APPNAME` to Config Variable Summary table, add Decision D8.
- **UI/UX:** N/A (CLI tool).

### Technical Impact
- **`always-nvim` main script:** +2 lines (1 default, 1 conditional export). Line count moves from ~271 to ~273 out of 300 budget.
- **`config` reference:** +1 line (new variable).
- **`install.sh` example config:** +3 lines (comment + variable).
- **Tests:** New test file for NVIM_APPNAME behavior.

---

## Section 3: Recommended Approach

**Selected: Option 1 — Direct Adjustment**

| Factor | Assessment |
|--------|------------|
| Effort | Low — ~2 lines in main script, config/install cosmetic updates |
| Risk | Low — additive change, no existing behavior modified |
| Timeline | Minimal — single small story |
| Line budget | Fits comfortably (273/300 after change) |
| MVP impact | None — MVP already complete |

**Alternatives considered:**
- Rollback: Not viable — nothing to roll back, all work is solid.
- MVP Review: Not viable — MVP is delivered and unaffected.

---

## Section 4: Detailed Change Proposals

### 4.1: `always-nvim` — Add default variable (Init Step 4)

```diff
 NA_FOCUS_DELAY="0.1"
+NA_NVIM_APPNAME=""
```

### 4.2: `always-nvim` — Export before terminal launch (Init Step 14)

```diff
 # ── Init Step 14: Launch terminal + Neovim (blocks until exit) ───────────────
+[ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"
 # shellcheck disable=SC2086
 $NA_TERMINAL_CMD nvim "${nvim_args[@]}" "$tmpfile"
```

### 4.3: `config` — Add reference variable

```diff
 NA_FOCUS_DELAY="0.1"
+NA_NVIM_APPNAME=""
```

### 4.4: `install.sh` — Update example config

```diff
 # Seconds to wait after refocus before paste
 # NA_FOCUS_DELAY="0.1"
+
+# Neovim APPNAME (uses ~/.config/<appname>/ for config, empty = normal config)
+# NA_NVIM_APPNAME=""
 CONFIGEOF
```

### 4.5: `architecture.md` — Config Variable Summary

```diff
 | `NA_PASTE_DELAY` | `0.2` | Seconds to wait after paste before clipboard restore |
+| `NA_NVIM_APPNAME` | (empty) | Neovim APPNAME — uses `~/.config/<appname>/` for config |
```

### 4.6: `architecture.md` — Decision D8

```diff
 | D7 | Missing config handling | Silent fallback to defaults | — | Zero friction. ... |
+| D8 | Neovim config isolation | `NVIM_APPNAME` env var via `NA_NVIM_APPNAME` | (empty) | Neovim 0.9+ natively supports `NVIM_APPNAME`. When set, Neovim reads `~/.config/<appname>/` instead of `~/.config/nvim/`. Empty default = no change. Opt-in for minimal configs. |
```

### 4.7: `epics.md` — New Epic 4 / Story 4.1

New epic appended to `epics.md` with full story definition and acceptance criteria.

---

## Section 5: Implementation Handoff

**Change scope classification:** Minor

**Handoff plan:**

| Role | Responsibility |
|------|----------------|
| **PM (John)** | ✅ Sprint Change Proposal (this document) — complete |
| **SM** | Create story file via `create-story` workflow for Story 4.1 |
| **Dev (Amelia)** | Implement Story 4.1 via `dev-story` workflow |
| **Maestro** | Final review and approval at each stage |

**Next steps (in order):**
1. Update `epics.md` with Epic 4 / Story 4.1 definition
2. Update `sprint-status.yaml` with Epic 4 / Story 4.1 entries
3. Run `create-story` workflow to generate story file
4. Run `dev-story` workflow to implement
5. Run tests, code review, mark done

**Success criteria:**
- `NA_NVIM_APPNAME=""` default preserves existing behavior (all 181 tests still pass)
- Non-empty `NA_NVIM_APPNAME` exports `NVIM_APPNAME` before terminal launch
- Config, install script, architecture docs all updated
- New tests validate both empty and non-empty cases
