---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - "inline-brainstorming-spec: always-nvim system-wide edit with neovim"
  - "reference: https://github.com/savedra1/clipse (inspiration project)"
date: 2026-03-10
author: Maestro
status: complete
---

# Product Brief: always-nvim

## Executive Summary

**always-nvim** is a lightweight, system-wide tool for Linux that lets you invoke Neovim in a floating terminal window from any application with a text input. Press a hotkey, edit with the full power of Neovim, and on close, the text is seamlessly inserted or replaced back in the original application.

The tool is inspired by the UX pattern pioneered by [clipse](https://github.com/savedra1/clipse) — a TUI clipboard manager that opens in a floating terminal window bound to a global hotkey. always-nvim applies this same "pop-up terminal TUI" concept to text editing: instead of managing clipboard history, it opens Neovim for composing or transforming text, then pastes the result back into the source application.

The V1 targets a single user (the developer) running Linux with tiling window managers (i3/Regolith on X11, Hyprland on Wayland). It is designed as a focused, stateless shell script with pluggable display-server backends, built for speed and reliability above all else.

---

## Core Vision

### Problem Statement

Linux power users who live in Neovim are forced to use inferior text editing experiences whenever they interact with web browsers, email clients, platform dashboards, or any GUI application with text inputs. These input fields offer none of the modal editing, macros, text objects, or plugin ecosystem that make Neovim the most efficient text editing environment available.

### Problem Impact

Every day, a Neovim-native developer encounters dozens of text inputs outside the terminal — composing emails, writing messages, filling forms, editing configuration in web UIs, drafting documentation in browser-based tools. Each interaction is a context switch from their most productive editing environment into a basic textarea with no power-editing capabilities. The cumulative friction is significant: slower editing, more errors, and the constant low-grade frustration of knowing a better tool exists but can't be used.

### Why Existing Solutions Fall Short

Several tools have attempted to bridge this gap, but each has significant limitations:

- **[vim-anywhere](https://github.com/cknadler/vim-anywhere)**: A similar concept (global hotkey opens Vim for editing), but it is primarily macOS-focused, unmaintained, and does not support Wayland or modern Linux display server configurations. It also does not handle the two-mode (insert new vs. edit selection) workflow cleanly.

- **[firenvim](https://github.com/nicknisi/firenvim)**: Embeds Neovim directly inside browser text fields via a browser extension. While clever, it is limited to browsers only, requires a browser extension (with all the maintenance and compatibility burden that entails), and cannot work with non-browser applications (desktop email clients, chat apps, system dialogs, etc.).

- **General clipboard managers (e.g., clipse)**: Tools like [clipse](https://github.com/savedra1/clipse) have proven the UX pattern — spawning a TUI in a floating terminal via a global hotkey works beautifully on tiling WMs. However, clipboard managers manage *history*, not *editing*. The architectural pattern (hotkey -> floating terminal -> TUI -> action -> return to source app) is the direct inspiration for always-nvim, repurposed for text editing rather than clipboard selection.

None of these tools deliver a clean, cross-display-server (X11 + Wayland), system-wide "edit with Neovim" experience on Linux.

### Proposed Solution

A single shell script (`always-nvim`) with pluggable backend modules that:

1. **Detects context automatically** — checks the primary selection to determine whether to open an empty editor (insert mode) or pre-load selected text (edit mode)
2. **Spawns Neovim in a floating terminal** — uses Alacritty (configurable) with a named window title so the WM can apply floating rules
3. **Blocks until editing is complete** — the script waits for the Neovim process to exit, keeping the flow synchronous and predictable
4. **Pastes the result back** — copies edited text to the clipboard, refocuses the original window, simulates Ctrl+V, then restores the user's original clipboard contents
5. **Abstracts display server differences** — X11 and Wayland backends implement the same function interface, selected automatically at runtime

The result is a tool that feels invisible: hotkey, edit, done. The text appears where it should, and the user's clipboard is untouched.

### Key Differentiators

- **System-wide, not browser-only**: Works with any application that accepts Ctrl+V paste — browsers, email clients, chat apps, IDEs, system dialogs
- **Cross-display-server**: First-class support for both X11 (i3/Regolith) and Wayland (Hyprland) from a single codebase via pluggable backends
- **Clipboard-safe**: Saves and restores clipboard state, ensuring the tool never corrupts the user's clipboard workflow
- **Zero-dependency architecture**: Pure shell script, no compilation, no runtime, no browser extension — just standard Unix tools
- **clipse-proven UX pattern**: Adopts the floating-terminal-TUI interaction model that clipse has proven works excellently on tiling WMs
- **Automatic mode detection**: Intelligently chooses between insert-new and edit-selection modes without requiring user intervention

---

## Target Users

### Primary User

**The Developer Himself (V1)**

- Linux power user who lives in Neovim as their primary text editor
- Uses tiling window managers: i3 (via Regolith) on X11 and Hyprland on Wayland
- Works across two distinct setups/distros (Regolith and Omarchy), requiring both X11 and Wayland support
- Primary text editing contexts outside the terminal: browser text inputs (email composition, platform dashboards, web forms), chat applications, and documentation tools
- Values speed and keyboard-driven workflows — every mouse interaction or context switch is friction
- Already comfortable with the "floating terminal TUI" pattern from using tools like clipse

### Secondary Users

For V1, there are no secondary users. The tool is a personal productivity tool built for a single developer's workflow. However, the architecture (pluggable backends, configurable terminal, shell-sourceable config) is deliberately designed so that the tool can serve a broader audience of Linux Neovim users in future versions.

### User Journey

1. **Discovery**: N/A for V1 (the developer is building it for himself)
2. **Installation**: Run `install.sh` which copies the script to a known location, creates `~/.config/always-nvim/`, and prints WM config snippets for i3 and Hyprland hotkey binding
3. **Configuration**: Add the suggested hotkey binding to i3/Hyprland config. Optionally customize `~/.config/always-nvim/config` (terminal emulator, dimensions, filetype, delays)
4. **Core Usage — Insert New Text**: User is in a browser textarea or any text input. Presses hotkey. Neovim opens in a floating terminal. User composes text with full Neovim power. Saves and quits (`:wq`). Text appears in the original input field. Total overhead: sub-second for the tool itself
5. **Core Usage — Edit Existing Text**: User selects text in any application. Presses hotkey. Neovim opens with the selected text loaded. User edits/transforms the text. Saves and quits. Edited text replaces the original selection. Clipboard is untouched
6. **Abort**: User opens Neovim but decides not to edit. Quits without saving (`:q!`). Nothing happens — no text is pasted, clipboard is restored, original application is untouched
7. **Success Moment**: The first time the user composes a multi-paragraph email using Neovim motions, macros, and text objects — then sees it appear perfectly in Gmail. "This is exactly what I needed."

---

## Success Metrics

### Reliability Metrics (Primary)

- **Clipboard integrity**: The user's clipboard contents are never lost or corrupted by the tool. After every invocation (successful edit, abort, or error), the clipboard is restored to its pre-invocation state. Target: 100% clipboard restoration rate
- **Paste success rate**: Text edited in Neovim is correctly pasted back into the source application. Target: >99% success rate across supported applications (browser inputs, chat apps, email clients)
- **Window refocus reliability**: The original application window is correctly refocused after Neovim closes. Target: >99% on both X11 and Wayland
- **Clean abort**: When the user quits without saving (`:q!`), absolutely nothing changes in the source application or clipboard. Target: 100%

### Speed Metrics (Primary)

- **Tool overhead (hotkey to Neovim ready)**: Time from hotkey press to Neovim cursor blinking and ready for input. Target: <500ms
- **Return overhead (Neovim exit to text pasted)**: Time from `:wq` to text appearing in the source application. Target: <300ms
- **Total round-trip feel**: The entire tool interaction (excluding actual editing time) should feel instantaneous — no perceptible lag or delay

### Business Objectives

This is a personal tool (V1). Business objectives are measured in developer productivity:

- **Daily usage**: The tool becomes a default part of the daily workflow, used multiple times per day for email composition, form filling, and text editing in browser-based tools
- **Workflow replacement**: Eliminates the need to draft text in a terminal Neovim instance and manually copy-paste into target applications

### Key Performance Indicators

| KPI | Target | Measurement Method |
|-----|--------|-------------------|
| Clipboard restoration rate | 100% | Manual testing across workflows |
| Paste success rate | >99% | Manual testing across target apps |
| Hotkey-to-ready latency | <500ms | Perceived feel during daily use |
| Exit-to-pasted latency | <300ms | Perceived feel during daily use |
| Daily invocations | >5/day after first week | Self-observation |
| Backend parity | Full feature parity X11/Wayland | Testing on both Regolith and Omarchy |

---

## MVP Scope

### Core Features

**1. Dual-Mode Operation**
- **Mode A — Insert New Text**: Open empty Neovim, paste result at cursor position on close
- **Mode B — Edit Selected Text**: Grab selected text, load into Neovim, replace selection with edited text on close
- **Automatic mode detection** via primary selection content check

**2. Display Server Backend Abstraction**
- Pluggable backend architecture with a common function interface (7 functions)
- **X11 backend** (`backends/x11.sh`): Uses xdotool + xclip
- **Wayland backend** (`backends/wayland.sh`): Uses wl-clipboard + wtype + hyprctl + jq
- Automatic backend detection via `$WAYLAND_DISPLAY` environment variable

**3. Clipboard Safety**
- Save clipboard contents before operation
- Restore clipboard contents after operation (on success, abort, or error)
- Clean temp files on all exit paths

**4. Window Management**
- Record active/focused window before launching Neovim
- Refocus original window after Neovim exits
- Configurable focus and paste delays for timing-sensitive applications

**5. Configuration**
- Shell-sourceable config file at `~/.config/always-nvim/config`
- Configurable: terminal emulator, window title flag, dimensions, filetype, nvim args, paste delay, focus delay, temp directory

**6. Installation**
- `install.sh` script that copies files, creates config directory, and prints WM hotkey configuration snippets for i3 and Hyprland

### Out of Scope for MVP

- **No daemon mode**: Each invocation is a stateless script execution. No background process, no pre-spawned terminals
- **No filetype auto-detection**: Filetype is set globally via config, not detected per-application
- **No rich text support**: Plain text only — no HTML, Markdown rendering, or formatted paste
- **No password field detection**: No mechanism to detect or avoid password inputs
- **No non-Hyprland Wayland compositors**: Wayland backend is Hyprland-specific (uses `hyprctl`). Sway, GNOME, KDE not supported in V1
- **No GUI notifications**: No visual feedback beyond the Neovim window itself
- **No crash recovery**: If the script is interrupted, temp files may be left behind (mitigated by `/tmp` auto-cleanup)
- **No clipboard manager integration**: Operates independently of clipboard managers like clipse
- **No undo support**: Once text is pasted back, there is no tool-level undo mechanism

### MVP Success Criteria

The MVP is successful when:

1. The developer uses `always-nvim` as the default method for composing and editing text in browser-based applications during daily work
2. Both X11 (Regolith) and Wayland (Hyprland) environments work reliably without environment-specific issues
3. Clipboard state is never corrupted during normal usage
4. The tool is fast enough that the overhead is imperceptible — it feels like Neovim is "just there" whenever needed
5. The abort path (`:q!`) is perfectly clean — no side effects, no traces

### Known Limitations

1. **Selection preservation on focus loss**: Mode B relies on the source application keeping text selected when focus moves to the floating terminal. Most GUI apps do this, but some may deselect
2. **Primary selection stale data**: A stale primary selection from a previous copy could incorrectly trigger Mode B. Mitigation: clear primary selection on cleanup
3. **Hyprland-only Wayland**: The Wayland backend uses `hyprctl` commands, limiting Wayland support to Hyprland (wlroots-based) compositors
4. **Timing sensitivity**: The focus and paste delays are configurable but may need tuning per-application. Some slow-rendering apps may need longer delays

---

## Future Vision

The MVP establishes the core interaction pattern and backend architecture. Future versions can expand along several axes:

### V2 — Performance & Polish
- **Daemon mode with pre-spawned terminal**: Eliminate terminal startup latency entirely by keeping a hidden terminal ready. Hotkey reveals it instantly
- **Filetype auto-detection**: Detect the source application (browser URL, app class) and automatically set the appropriate Neovim filetype (markdown for emails, yaml for config UIs, etc.)
- **GUI notifications**: Subtle desktop notifications on success/failure using `notify-send` or equivalent

### V2 — Broader Compatibility
- **Additional Wayland compositors**: Add backends for Sway (wlroots, similar to Hyprland), GNOME (via `gdbus` / `xdg-desktop-portal`), and KDE
- **Multiple terminal emulator support**: Test and document configurations for kitty, wezterm, foot, and other popular terminal emulators

### V3 — Power Features
- **Multiple named profiles**: Different configurations for different contexts (email profile with markdown filetype, code review profile with diff filetype, etc.)
- **Crash recovery**: Detect and recover temp files from interrupted sessions
- **Undo support**: Store pre-edit text and provide a "revert last edit" hotkey
- **Clipboard manager integration**: Coordinate with tools like clipse to avoid conflicts and share clipboard state

### Long-Term Possibilities
- **Community adoption**: If the tool proves useful, package for major Linux distributions (AUR, nixpkgs, etc.) following the clipse distribution model
- **Plugin architecture**: Allow users to define pre/post-processing hooks (e.g., auto-format on paste, spell-check before return)
- **Cross-platform exploration**: Investigate macOS support using similar clipboard/keystroke simulation tools

---

## Technical Context

### Architecture

The tool follows a simple, linear architecture:

```
[Global Hotkey] → [Shell Script] → [Backend Detection] → [Clipboard Save]
    → [Mode Detection] → [Spawn Terminal+Neovim] → [Block/Wait]
    → [Read Result] → [Clipboard Paste] → [Refocus] → [Simulate Ctrl+V]
    → [Restore Clipboard] → [Cleanup]
```

### Project Structure

```
always-nvim/
├── always-nvim              ← main entry point script (~80-100 lines)
├── backends/
│   ├── x11.sh               ← X11 backend functions (~40 lines)
│   └── wayland.sh           ← Wayland/Hyprland backend functions (~40 lines)
├── config.example           ← documented example config
├── install.sh               ← installer with WM config snippets
├── LICENSE
└── README.md
```

### Dependencies

| Context | Required Tools |
|---------|---------------|
| Both | neovim, alacritty (or configured terminal) |
| X11 | xdotool, xclip |
| Wayland/Hyprland | wl-clipboard, wtype, jq |

### Backend Interface Contract

Both backends implement the same 7-function interface:

| Function | Purpose |
|----------|---------|
| `backend_get_selection()` | Return currently selected text (primary selection) |
| `backend_copy_to_clipboard()` | Copy stdin to system clipboard |
| `backend_get_clipboard()` | Return current clipboard contents |
| `backend_set_clipboard()` | Set clipboard from stdin |
| `backend_simulate_paste()` | Simulate Ctrl+V keystroke |
| `backend_get_active_window()` | Return focused window identifier |
| `backend_refocus_window()` | Refocus a previously saved window |

---

*This product brief serves as the strategic foundation for always-nvim. All subsequent design, architecture, and development work should trace back to the vision, user needs, and success criteria documented here.*
