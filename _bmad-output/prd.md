---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
inputDocuments:
  - "product-brief: _bmad-output/product-brief.md"
  - "inline-brainstorming-spec: always-nvim system-wide edit with neovim"
  - "reference: https://github.com/savedra1/clipse (inspiration project)"
classification:
  projectType: cli_tool
  domain: developer_tools
  complexity: low
  projectContext: greenfield
workflowType: prd
date: 2026-03-10
author: Maestro
status: complete
---

# Product Requirements Document - always-nvim

**Author:** Maestro
**Date:** 2026-03-10

## Executive Summary

**always-nvim** is a system-wide Linux tool that opens Neovim in a floating terminal window from any application via a global hotkey. Users edit text with full Neovim capabilities, and on close, the result is pasted back into the source application. The tool targets a single developer running tiling window managers (i3/Regolith on X11, Hyprland on Wayland).

The core interaction pattern — hotkey triggers a floating terminal TUI, user acts, result returns to source app — is directly inspired by [clipse](https://github.com/savedra1/clipse), a clipboard manager that proved this UX pattern works exceptionally well on tiling WMs. always-nvim repurposes the pattern for text editing instead of clipboard history.

The tool is a stateless Bash shell script (~250 lines total) with pluggable display-server backend modules. It detects context automatically (insert new text vs. edit selected text), manages clipboard state safely, and abstracts X11/Wayland differences behind a 7-function interface contract.

### What Makes This Special

- **System-wide scope**: Works with any application that accepts Ctrl+V — browsers, email clients, chat apps, IDEs, system dialogs. Not limited to a browser extension or single ecosystem.
- **Cross-display-server from a single codebase**: Pluggable backends for X11 (xdotool + xclip) and Wayland/Hyprland (wl-clipboard + wtype + hyprctl) with identical behavior, selected automatically at runtime.
- **Clipboard-safe by design**: Every code path — success, abort, error — saves and restores the user's clipboard contents. The tool never corrupts clipboard state.
- **Automatic mode detection**: Checks primary selection to determine whether to open an empty editor (Mode A: insert new) or pre-load selected text (Mode B: edit selection). Zero user intervention required.
- **Zero-dependency architecture**: Pure Bash, no compilation, no runtime, no browser extension. Standard Unix tools only.

## Project Classification

- **Project Type:** CLI/Shell Tool
- **Domain:** Developer Tools / Productivity
- **Complexity:** Low (no regulated domain, no compliance, straightforward technical stack)
- **Project Context:** Greenfield (new project, no existing codebase)

## Success Criteria

### User Success

- The tool becomes the default method for composing and editing text outside the terminal within the first week of use
- Editing in Neovim via hotkey feels as natural as opening a terminal — zero friction, zero hesitation
- The "aha!" moment: composing a multi-paragraph email using Neovim motions and macros, then seeing it appear perfectly in Gmail

### Business Success

This is a personal productivity tool (V1). Success is measured by:

- **Daily usage**: >5 invocations/day after the first week of adoption
- **Workflow replacement**: Eliminates the draft-in-terminal-then-copy-paste workflow entirely
- **Backend parity**: Full feature parity between X11 (Regolith) and Wayland (Hyprland) environments with no environment-specific issues

### Technical Success

| Metric | Target | Measurement |
|--------|--------|-------------|
| Clipboard restoration rate | 100% | Manual testing: clipboard contents identical before/after every invocation (success, abort, error) |
| Paste success rate | >99% | Manual testing across browser inputs, chat apps, email clients on both X11 and Wayland |
| Window refocus reliability | >99% | Manual testing: original window regains focus after Neovim closes on both display servers |
| Clean abort (`:q!`) | 100% | No text pasted, no clipboard corruption, no temp files left behind |
| Hotkey-to-Neovim-ready | <500ms | Perceived latency from hotkey press to Neovim cursor blinking |
| Exit-to-text-pasted | <300ms | Perceived latency from `:wq` to text appearing in source application |

### Measurable Outcomes

- Total tool overhead (excluding editing time) is imperceptible — the tool feels like Neovim is "just there" whenever needed
- Both X11 and Wayland backends behave identically from the user's perspective
- No clipboard data loss incidents during normal daily use over a 30-day period

## Product Scope

### MVP - Minimum Viable Product

The MVP delivers a complete, reliable "hotkey to edit to paste" loop on both X11 and Wayland:

1. **Dual-mode operation** with automatic detection (insert new / edit selection)
2. **X11 backend** (xdotool + xclip) for i3/Regolith
3. **Wayland backend** (wl-clipboard + wtype + hyprctl + jq) for Hyprland
4. **Clipboard save/restore** on all code paths (success, abort, error, signal trap)
5. **Window tracking and refocus** after Neovim exits
6. **Shell-sourceable config file** at `~/.config/always-nvim/config`
7. **install.sh** with file copy and WM config snippets for i3 and Hyprland

### Growth Features (Post-MVP)

- **Daemon mode with pre-spawned terminal**: Eliminate terminal startup latency by keeping a hidden terminal ready; hotkey reveals it instantly
- **Filetype auto-detection**: Detect source application (browser URL, app class) and set Neovim filetype automatically (markdown for emails, yaml for config UIs)
- **Additional Wayland compositors**: Sway (wlroots), GNOME (gdbus/xdg-desktop-portal), KDE
- **GUI notifications**: Desktop notifications on success/failure via `notify-send`
- **Multiple terminal emulator support**: Documented configurations for kitty, wezterm, foot

### Vision (Future)

- **Named profiles**: Context-specific configurations (email = markdown, code review = diff, etc.)
- **Crash recovery**: Detect and recover temp files from interrupted sessions
- **Undo support**: Store pre-edit text and provide a "revert last edit" hotkey
- **Clipboard manager integration**: Coordinate with clipse to avoid conflicts
- **Plugin architecture**: Pre/post-processing hooks (auto-format on paste, spell-check before return)
- **Community distribution**: AUR, nixpkgs packages following clipse's distribution model
- **Cross-platform**: Investigate macOS support

## User Journeys

### Journey 1: Dev Composing a New Email (Mode A - Insert New)

**Alex** is writing a detailed response to a teammate about a production incident. The Gmail compose window has a blank textarea.

Alex presses the global hotkey. A floating Neovim window appears in under 500ms. Alex writes a structured response using Neovim motions — `ciw` to fix a word, `yy3p` to duplicate a line template, `:s/old/new/g` to batch-rename a service reference. The text is dense and precise. Alex types `:wq`.

The floating terminal disappears. The cursor is back in Gmail. The entire response appears in the compose field. Alex checks the clipboard — it still contains the log snippet copied earlier. Nothing was disturbed. Total tool overhead: sub-second.

**Capabilities revealed:** Empty file creation, terminal spawn with window title, Neovim launch with configurable filetype, clipboard save/restore, paste simulation, window refocus.

### Journey 2: Dev Editing Existing Text (Mode B - Edit Selection)

**Alex** has a Jira comment open in the browser with a paragraph of text that needs restructuring. Alex selects the paragraph with the mouse, then presses the global hotkey.

Neovim opens with the selected text already loaded in the buffer. Alex uses `dd`, `p`, and visual block mode to restructure the paragraph. Alex types `:wq`.

The floating window closes. The browser regains focus. The edited text replaces the original selection (which was still highlighted). The clipboard still contains what it had before. The original text is gone; the restructured version is in place.

**Capabilities revealed:** Primary selection capture, temp file pre-population, content change detection, selected-text replacement via paste, clipboard integrity across Mode B.

### Journey 3: Dev Aborts an Edit (Clean Abort)

**Alex** presses the hotkey by accident while reading (not composing). Neovim opens with an empty buffer (no text was selected, so Mode A). Alex realizes the mistake and types `:q!`.

Nothing happens. No text is pasted. The original application stays focused. The clipboard is untouched. No temp files remain in `/tmp`. The tool is completely invisible — as if the hotkey was never pressed.

**Capabilities revealed:** Abort detection (empty/unchanged file), clipboard restore on abort, temp file cleanup on all exit paths, no-side-effect guarantee.

### Journey 4: Dev Switches Between X11 and Wayland

**Alex** uses Regolith (i3/X11) at the office workstation and Omarchy (Hyprland/Wayland) on the laptop. The same `always-nvim` script is installed on both machines via the same install process.

On X11, the script detects `$WAYLAND_DISPLAY` is unset, sources `backends/x11.sh`, and uses xdotool + xclip. On Wayland, it detects `$WAYLAND_DISPLAY` is set, sources `backends/wayland.sh`, and uses wl-clipboard + wtype + hyprctl. Both environments produce identical behavior: hotkey → Neovim → edit → paste → restore.

Alex never thinks about which display server is running. The tool just works.

**Capabilities revealed:** Automatic backend detection via environment variable, backend interface contract (7 functions), identical behavior across display servers, per-backend dependency resolution.

### Journey Requirements Summary

| Journey | Mode | Key Capabilities |
|---------|------|-----------------|
| New email composition | A (Insert) | Spawn, edit, paste, restore |
| Edit existing text | B (Edit) | Selection capture, replace, restore |
| Accidental invocation | Abort | Clean exit, no side effects |
| Cross-environment | Both | Backend detection, interface parity |

## CLI Tool Specific Requirements

### Project-Type Overview

always-nvim is a non-interactive shell script invoked via global hotkey binding configured in the window manager. It has no persistent process, no daemon, no TUI of its own — it orchestrates Neovim in a terminal and manages clipboard/window state around it.

### Technical Architecture Considerations

**Execution Model:**
- Single-shot script execution per invocation (no daemon, no state between runs)
- Linear flow: detect → save → spawn → wait → read → paste → restore → cleanup
- All state is local to the invocation (temp files, saved clipboard, window ID)

**Backend Abstraction:**
- `$WAYLAND_DISPLAY` environment variable determines backend at runtime
- Backend files sourced via `. backends/x11.sh` or `. backends/wayland.sh`
- All backends implement identical 7-function interface contract
- No fallback between backends — if the wrong backend loads, the script fails cleanly

**Terminal Integration:**
- Alacritty (default, configurable) spawned with `--title "always-nvim"` flag
- Window manager matches on title string for floating rules
- Script blocks on terminal process exit (synchronous flow)

**Temp File Management:**
- `mktemp` creates `/tmp/always-nvim-XXXXXX` per invocation
- Trap handler ensures cleanup on EXIT, INT, TERM signals
- File content compared to detect abort (empty or unchanged = abort)

### Configuration Architecture

| Option | Default | Purpose |
|--------|---------|---------|
| `NA_TERMINAL` | `alacritty` | Terminal emulator command |
| `NA_TERM_TITLE_FLAG` | `--title` | Flag to set window title |
| `NA_WIDTH` | `80` | Terminal width (columns) |
| `NA_HEIGHT` | `24` | Terminal height (rows) |
| `NA_FILETYPE` | `markdown` | Neovim filetype for new buffers |
| `NA_NVIM_ARGS` | `""` | Additional Neovim arguments |
| `NA_PASTE_DELAY` | `0.15` | Seconds to wait after paste before clipboard restore |
| `NA_FOCUS_DELAY` | `0.05` | Seconds to wait after refocus before paste simulation |
| `NA_TMPDIR` | `/tmp` | Directory for temp files |

Config file: `~/.config/always-nvim/config` (shell-sourceable, loaded via `source` if exists)

### Implementation Considerations

**Window Manager Configuration (User-Provided):**

i3/Regolith:
```
for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center
```

Hyprland:
```
windowrulev2 = float,title:^(always-nvim)$
windowrulev2 = size 800 600,title:^(always-nvim)$
windowrulev2 = center,title:^(always-nvim)$
```

**Hotkey Binding (User-Provided):**

i3: `bindsym $mod+e exec always-nvim`
Hyprland: `bind = $mainMod, E, exec, always-nvim`

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Problem-solving MVP — deliver the core "edit with Neovim anywhere" loop with maximum reliability. Zero polish features, zero optional features. The smallest thing that validates the assumption: "a pop-up Neovim window is the right UX for system-wide text editing on Linux."

**Resource Requirements:** Single developer (the author). Pure Bash, no build tools, no dependencies beyond standard Linux tools. Estimated: ~250 lines of Bash across 4 files.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
- Journey 1 (Insert new text) — full support
- Journey 2 (Edit selected text) — full support
- Journey 3 (Clean abort) — full support
- Journey 4 (Cross-environment) — full support (X11 + Hyprland only)

**Must-Have Capabilities:**
1. Backend detection and loading (X11 vs Wayland)
2. Clipboard save and restore on all paths
3. Active window recording and refocus
4. Primary selection check for mode detection
5. Temp file creation, writing, reading, cleanup
6. Terminal + Neovim spawn with blocking wait
7. Content change detection (abort if empty/unchanged)
8. Clipboard-based paste simulation (Ctrl+V)
9. Configurable delays for focus and paste timing
10. Shell-sourceable config file loading
11. Signal trap for cleanup on interrupt
12. Install script with WM config snippets

### Post-MVP Features

**Phase 2 (Growth):**
- Daemon mode with pre-spawned terminal for instant startup
- Filetype auto-detection based on source application
- Sway compositor support
- `notify-send` feedback on success/failure
- kitty, wezterm terminal emulator support

**Phase 3 (Expansion):**
- Named editing profiles
- Crash recovery for interrupted sessions
- Undo/revert last edit hotkey
- Clipboard manager integration (clipse coordination)
- Pre/post-processing plugin hooks
- GNOME/KDE Wayland compositor support

### Risk Mitigation Strategy

**Technical Risks:**
- *Selection preservation on focus loss*: Some apps may deselect text when focus moves to the floating terminal. Mitigation: document known-good apps, test broadly, accept as known limitation for V1.
- *Primary selection stale data*: A stale primary selection from a previous copy could incorrectly trigger Mode B. Mitigation: accept as known limitation; consider clearing primary selection in cleanup.
- *Timing sensitivity*: Paste and focus delays vary by application. Mitigation: configurable `NA_PASTE_DELAY` and `NA_FOCUS_DELAY` values.

**Market Risks:** None for V1 (personal tool). Future risk: if broader adoption is pursued, Hyprland-only Wayland support limits audience. Mitigation: pluggable backend architecture makes adding compositors straightforward.

**Resource Risks:** Single developer, but scope is minimal (~250 lines). Risk of scope creep is the primary concern. Mitigation: strict MVP boundaries defined above.

## Functional Requirements

### Backend Detection & Loading

- FR1: The script can detect whether the current session is X11 or Wayland via `$WAYLAND_DISPLAY` environment variable
- FR2: The script can source the correct backend module (`x11.sh` or `wayland.sh`) based on detected display server
- FR3: The script can fail cleanly with a descriptive error if required backend dependencies are not installed

### Clipboard Management

- FR4: The script can save the current system clipboard contents to a variable before any operations
- FR5: The script can restore previously saved clipboard contents after all operations complete
- FR6: The script can restore clipboard contents on abort (`:q!` with empty/unchanged file)
- FR7: The script can restore clipboard contents on signal interruption (SIGINT, SIGTERM)
- FR8: The script can copy arbitrary text content to the system clipboard

### Mode Detection

- FR9: The script can read the current primary selection (X11 primary / Wayland primary)
- FR10: The script can determine Mode A (insert new) when primary selection is empty
- FR11: The script can determine Mode B (edit selection) when primary selection contains text

### Temp File Management

- FR12: The script can create a unique temporary file in the configured temp directory
- FR13: The script can write captured selection text to the temp file (Mode B)
- FR14: The script can read the temp file contents after Neovim exits
- FR15: The script can detect abort conditions (temp file empty or unchanged from original)
- FR16: The script can delete the temp file on all exit paths (success, abort, error, signal)

### Terminal & Editor Orchestration

- FR17: The script can spawn a configured terminal emulator with a specific window title (`always-nvim`)
- FR18: The script can launch Neovim inside the terminal with the temp file and configured filetype
- FR19: The script can pass additional Neovim arguments from configuration
- FR20: The script can block execution until the terminal process exits

### Window Management

- FR21: The script can record the currently focused window identifier before spawning the terminal
- FR22: The script can refocus the previously recorded window after Neovim exits
- FR23: The script can wait a configurable delay after refocus before simulating paste

### Paste Simulation

- FR24: The script can simulate a Ctrl+V keystroke in the focused application
- FR25: The script can wait a configurable delay after paste before restoring the clipboard

### Configuration

- FR26: The script can load a shell-sourceable config file from `~/.config/always-nvim/config` if it exists
- FR27: The script can operate with sensible defaults when no config file is present
- FR28: Users can configure: terminal emulator, title flag, dimensions, filetype, nvim args, paste delay, focus delay, temp directory

### Installation

- FR29: The install script can copy all script files to a user-accessible location
- FR30: The install script can create the `~/.config/always-nvim/` directory and example config
- FR31: The install script can display WM hotkey configuration snippets for i3 and Hyprland

### Backend Interface Contract

- FR32: Each backend implements `backend_get_selection()` to return currently selected text
- FR33: Each backend implements `backend_copy_to_clipboard()` to copy stdin to system clipboard
- FR34: Each backend implements `backend_get_clipboard()` to return current clipboard contents
- FR35: Each backend implements `backend_set_clipboard()` to set clipboard from stdin
- FR36: Each backend implements `backend_simulate_paste()` to simulate Ctrl+V keystroke
- FR37: Each backend implements `backend_get_active_window()` to return focused window identifier
- FR38: Each backend implements `backend_refocus_window()` to refocus a previously saved window

## Non-Functional Requirements

### Performance

- NFR1: Hotkey press to Neovim cursor ready shall complete in under 500ms as perceived by the user during normal desktop usage
- NFR2: Neovim exit to text pasted in source application shall complete in under 300ms as perceived by the user
- NFR3: Clipboard save and restore operations shall add no perceptible latency (<50ms each)
- NFR4: The complete script (excluding Neovim editing time) shall consume less than 50MB of memory

### Reliability

- NFR5: Clipboard contents shall be restored to pre-invocation state on 100% of invocations, measured across success, abort, error, and signal-interrupted paths
- NFR6: Temp files shall be cleaned up on 100% of invocations, including signal-interrupted paths, measured by checking `/tmp/always-nvim-*` after each invocation
- NFR7: The script shall not leave orphan processes after any exit path
- NFR8: The tool shall function correctly after 100 consecutive invocations without system restart

### Compatibility

- NFR9: X11 backend shall function identically to Wayland backend from the user's perspective, verified by running the same test scenarios on both Regolith (i3/X11) and Omarchy (Hyprland/Wayland)
- NFR10: The tool shall work with Alacritty as the default terminal and support configuration for alternative terminals that accept a `--title` equivalent flag
- NFR11: The tool shall paste correctly into Chromium-based browsers, Firefox, Slack (Electron), and standard GTK/Qt text inputs

### Maintainability

- NFR12: Total codebase shall remain under 300 lines of Bash (excluding comments and blank lines)
- NFR13: Each backend module shall remain under 50 lines of Bash
- NFR14: Adding a new display-server backend shall require only creating a new file implementing the 7-function interface contract, with no changes to the main script

---

*This PRD serves as the foundation for all subsequent design, architecture, and development work on always-nvim. All implementation decisions should trace back to the requirements and vision documented here. Update this document as the project evolves.*
