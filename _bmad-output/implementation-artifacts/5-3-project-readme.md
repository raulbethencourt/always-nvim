# Story 5.3: Project README

Status: review

## Story

As a user,
I want a comprehensive, well-structured README.md that explains what always-nvim does, how to install it, how to use it, and how to configure it,
so that I can quickly understand and set up the tool on a new machine.

## Acceptance Criteria

1. **Given** the project has no README.md **When** this story is implemented **Then** a `README.md` exists at the repository root

2. **Given** the README has a header section **When** a user first visits the repository **Then** they see: project name, one-line description, a brief "what it does" paragraph, and a visual or textual diagram showing the workflow (hotkey -> floating Neovim -> edit -> paste back)

3. **Given** the README has a features section **When** a user wants to understand capabilities **Then** they see: dual mode (insert new / edit selected), X11 and Wayland/Hyprland support, automatic clipboard save/restore, configurable terminal/filetype/nvim args/delays, NVIM_APPNAME support, lock file protection, stale file cleanup

4. **Given** the README has a requirements section **When** a user checks prerequisites **Then** they see: Bash 4.0+, Neovim 0.9+, terminal emulator (Alacritty default), X11 tools (xclip, xdotool), Wayland tools (wl-clipboard, wtype, hyprctl, jq)

5. **Given** the README has an installation section **When** a user wants to install **Then** they see: clone the repository, run `./install.sh`, what the install script does, manual installation alternative

6. **Given** the README has a configuration section **When** a user wants to customize **Then** they see: config file location (`~/.config/always-nvim/config`), table of ALL `NA_*` variables with defaults and descriptions, example config

7. **Given** the README has a keybindings section **When** a user wants to set up their window manager **Then** they see: i3 config (hotkey + floating rules), Hyprland config (hotkey + windowrulev2 rules), explanation of `always-nvim` window title for WM matching

8. **Given** the README has a usage section **When** a user wants to understand how to use the tool **Then** they see: basic usage, Mode A (insert new), Mode B (edit selection), abort (`:q!` or `:cq`), command-line flags (`--help`, `--version`)

9. **Given** the README has a performance tips section **When** a user wants faster startup **Then** they see: `NA_NVIM_APPNAME` documentation with instructions for creating a minimal Neovim config for always-nvim (spike finding from Story 5.1: reduces nvim startup from ~134ms to ~14ms)

10. **And** the README uses clear Markdown formatting with headers, code blocks, and tables
11. **And** the README is user-friendly and approachable (not overly technical)
12. **And** the README does not include internal architecture details (those live in architecture.md)
13. **And** the tone is professional but friendly

## Tasks / Subtasks

- [x] Task 1: Create README.md with header and features (AC: #1, #2, #3)
  - [x] 1.1: Write project name, one-line description, "what it does" paragraph
  - [x] 1.2: Create a textual workflow diagram (hotkey -> terminal -> edit -> paste)
  - [x] 1.3: Write features list covering all capabilities

- [x] Task 2: Requirements and installation (AC: #4, #5)
  - [x] 2.1: Write requirements section with all dependencies by backend
  - [x] 2.2: Write installation section (clone + `./install.sh`)
  - [x] 2.3: Document what install.sh does (copies files, creates config, shows WM snippets)
  - [x] 2.4: Write manual installation alternative

- [x] Task 3: Configuration section (AC: #6)
  - [x] 3.1: Document config file location
  - [x] 3.2: Create table of ALL NA_* variables with defaults and descriptions
  - [x] 3.3: Include example config snippet

- [x] Task 4: Keybindings / WM configuration (AC: #7)
  - [x] 4.1: Write i3 hotkey + floating window rules
  - [x] 4.2: Write Hyprland hotkey + windowrulev2 rules
  - [x] 4.3: Explain the `always-nvim` window title matching

- [x] Task 5: Usage section (AC: #8)
  - [x] 5.1: Write basic usage flow
  - [x] 5.2: Document Mode A (insert new) and Mode B (edit selection)
  - [x] 5.3: Document abort behavior (`:q!`, `:cq`)
  - [x] 5.4: Document `--help` and `--version` flags

- [x] Task 6: Performance tips section (AC: #9)
  - [x] 6.1: Document `NA_NVIM_APPNAME` as the performance strategy
  - [x] 6.2: Provide example minimal init.lua for always-nvim
  - [x] 6.3: Include timing data from spike (134ms -> 14ms nvim startup)

- [x] Task 7: Final polish and validation (AC: #10, #11, #12, #13)
  - [x] 7.1: Review formatting, headers, code blocks, tables
  - [x] 7.2: Verify user-friendly tone, no internal architecture details
  - [x] 7.3: Ensure all NA_* variables from config reference are documented

## Dev Notes

### CRITICAL: This Is a Documentation Story, Not a Code Story

This story creates **one new file**: `README.md` at the repository root. No source code changes, no test changes. The red-green-refactor cycle does not apply. Instead:

1. Write the README content based on the acceptance criteria
2. Verify all sections are present and accurate
3. Cross-reference with source files to ensure completeness

### Content Sources (Read These for Accurate Documentation)

The README content must be derived from actual source files, not assumptions:

- **`always-nvim`** (173 lines) — Main script, all init steps, config variables with defaults (lines 35-42), dependency checks (lines 92-106), mode detection (lines 124-125)
- **`config`** (13 lines) — Reference config file with all NA_* variables and defaults
- **`install.sh`** (114 lines) — Installation process, config creation, WM instruction output
- **`backends/x11.sh`** (46 lines) — X11 dependencies: xclip, xdotool
- **`backends/wayland.sh`** (54 lines) — Wayland dependencies: wl-paste, wl-copy, wtype, hyprctl, jq

### Config Variables (Complete List from Source)

From `always-nvim` lines 35-42:
| Variable | Default | Purpose |
|----------|---------|---------|
| `NA_TERMINAL_CMD` | `alacritty --title always-nvim -e` | Terminal command with title flag |
| `NA_BACKEND` | `auto` | Backend selection: auto, x11, wayland |
| `NA_CLEAR_PRIMARY` | `true` | Clear primary selection after run |
| `NA_FILETYPE` | `md` | Temp file extension / Neovim filetype |
| `NA_NVIM_ARGS` | `""` (empty) | Extra Neovim arguments |
| `NA_PASTE_DELAY` | `0.2` | Seconds to wait after paste |
| `NA_FOCUS_DELAY` | `0.1` | Seconds to wait after refocus |
| `NA_NVIM_APPNAME` | `""` (empty) | Neovim APPNAME for config isolation |

### Performance Tip (From Spike Story 5.1)

Story 5.1 measured startup times on the actual system:
- Full Neovim config: **134ms** startup
- Empty `NVIM_APPNAME` (minimal config): **14ms** startup (90% reduction)
- Terminal spawn (Alacritty): **184ms** (fixed cost, dominates total latency)

The README should recommend setting `NA_NVIM_APPNAME` for users who want faster startup, with a brief example of a minimal `~/.config/always-nvim/init.lua`.

### WM Configuration (From install.sh lines 86-101)

i3 config:
```
bindsym $mod+e exec always-nvim
for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center
```

Hyprland config:
```
bind = $mainMod, E, exec, always-nvim
windowrulev2 = float,title:^(always-nvim)$
windowrulev2 = size 800 600,title:^(always-nvim)$
windowrulev2 = center,title:^(always-nvim)$
windowrulev2 = pin,title:^(always-nvim)$
```

### Anti-Patterns to AVOID

1. **DO NOT** include internal architecture details (decisions, ADCs, init step numbering) — those live in architecture.md
2. **DO NOT** mention the BMAD methodology, epics, stories, or sprint tracking
3. **DO NOT** add badges, CI status, or contributor guidelines (not applicable yet)
4. **DO NOT** document the `NA_SERVER_ENABLED` / `NA_SERVER_SOCKET` variables — the server daemon was a NO-GO (Story 5.1)
5. **DO NOT** modify any existing source files

### Tone and Style

- Professional but friendly — the user is an intermediate developer
- Show, don't tell — use code blocks and examples
- Keep it scannable — headers, bullet points, tables
- No emojis (per project convention)

### Project Structure Notes

- New file: `README.md` at repository root
- No other files created or modified

### References

- [Source: always-nvim lines 35-42] — All config variable defaults
- [Source: always-nvim lines 92-106] — Dependency checks (complete list)
- [Source: always-nvim lines 124-125] — Mode detection logic
- [Source: config] — Reference config file (13 lines)
- [Source: install.sh lines 51-79] — Example config with comments
- [Source: install.sh lines 86-101] — WM configuration snippets
- [Source: backends/x11.sh] — X11 tool dependencies
- [Source: backends/wayland.sh] — Wayland tool dependencies
- [Source: _bmad-output/implementation-artifacts/5-1-neovim-server-architecture-spike.md] — Startup timing data
- [Source: _bmad-output/planning-artifacts/epics.md lines 804-878] — Story 5.3 acceptance criteria

### Previous Story Intelligence (from Story 5.1)

- Agent model: claude-opus-4.6 (github-copilot)
- Neovim version on system: v0.12.0-dev
- Story 5.1 was a research spike — NO-GO for server daemon, `NA_NVIM_APPNAME` is the performance strategy
- Startup timing: full config 134ms, empty appname 14ms, terminal spawn 184ms (dominates)
- Story 5.2 was cancelled based on spike findings
- Budget: 273/300 lines (27 remaining) — but this story adds no runtime code
- All 188 tests pass across 20 test files
- Test files: 01-11, 13-20 (no file 12), next available: 21

## Dev Agent Record

### Agent Model Used

claude-opus-4.6 (github-copilot)

### Debug Log References

No debug issues encountered. Documentation-only story, no code changes.

### Completion Notes List

- Created comprehensive README.md (251 lines) at repository root
- All 13 acceptance criteria satisfied and validated
- Content derived entirely from source files: always-nvim (lines 35-42, 92-106, 124-125), config, install.sh, backends/x11.sh, backends/wayland.sh
- All 8 NA_* config variables documented with accurate defaults from source
- Performance tips include actual timing data from Story 5.1 spike (134ms -> 14ms)
- No internal architecture details, no BMAD references, no emojis per anti-pattern rules
- WM configuration snippets match install.sh output exactly (lines 86-101)
- All 188 existing tests pass, no regressions

### File List

- README.md (new)

## Change Log

- 2026-03-13: Created README.md with complete user documentation covering all acceptance criteria (AC #1-#13)
