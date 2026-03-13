# Sprint Change Proposal: UI Color Enhancement

**Date:** 2026-03-13
**Triggered by:** Post-MVP polish request (Maestro)
**Status:** Approved
**Scope:** Minor

---

## Section 1: Issue Summary

The install script (`install.sh`) and main script (`always-nvim`) output plain unformatted text despite having the shell library's ANSI color constants already loaded. The library's `ui.sh` module provides `GREENF`, `YELLOWF`, `CYANF`, `BLUEF`, `REDF`, `RESET`, etc. — documented in architecture as "for user-facing error/status messages" — but this capability is underutilized. Adding color improves readability and gives a polished developer experience.

## Section 2: Impact Analysis

- **Epic Impact:** None. All 4 epics are done. No epic changes.
- **Story Impact:** No existing stories affected. No new stories required.
- **Artifact Conflicts:** None. Architecture already documents color usage as intended.
- **Technical Impact:**
  - `install.sh`: ~15 printf lines gain color formatting. Fallback path needs empty color var definitions.
  - `always-nvim`: 1 line gains color formatting (version output). 0 additional lines.
  - **NFR12 (300-line budget):** `install.sh` is tooling (not counted). `always-nvim` stays at 173 lines.

## Section 3: Recommended Approach

**Direct Adjustment** — modify 2 existing files with color enhancements. No structural changes, no new files, no new dependencies.

- Effort: **Low**
- Risk: **Low**
- Timeline impact: **None**

## Section 4: Detailed Change Proposals

### Proposal 1: `install.sh` — Colored Output

Add colored output using library color constants:

| Element | Color | Rationale |
|---|---|---|
| Section headers (`===...===`) | `CYANF` | Visual section breaks |
| Sub-headers (`---...---`) | `BLUEF` | Secondary hierarchy |
| Success indicators (`Installed:`, `Created:`, checkmark) | `GREENF` | Positive confirmation |
| Warning indicators (caution, `NOT in PATH`) | `YELLOWF` | Attention needed |
| Preserved config notice | `YELLOWF` | Informational, not a fresh action |
| Completion message | `GREENF` | Final success signal |

**Fallback handling:** Define empty color variables in the fallback branch (when `.toolbox` is unavailable) to prevent undefined variable errors.

### Proposal 2: `always-nvim` — Version Output Color

Colorize tool name in `--version` output:

```bash
# OLD:
printf '%s\n' "always-nvim $NA_VERSION_TO_SHOW"

# NEW:
printf '%s\n' "${GREENF}always-nvim${RESET} $NA_VERSION_TO_SHOW"
```

**Line budget impact:** 0 additional lines.

## Section 5: Implementation Handoff

- **Scope:** Minor — direct implementation by dev team
- **Recipient:** Dev agent (Amelia)
- **Responsibilities:** Implement color changes, verify fallback path, run full test suite
- **Success criteria:** All 188 tests pass, colored output displays correctly, fallback path produces readable (uncolored) output
