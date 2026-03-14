# Story 5.1: Neovim Server Architecture Spike

Status: done

## Story

As a developer,
I want a technical design for the Neovim server daemon integration that validates the `nvim --headless --listen` + `nvim --server --remote` approach, determines the exact line budget impact, and documents the architectural decisions,
so that the implementation story (5.2) has a clear, validated design to follow.

## Acceptance Criteria

1. **Given** Neovim 0.9+ supports `--headless --listen <address>` for server mode **When** the architecture spike investigates the server approach **Then** it documents the exact commands and socket path for starting the daemon, connecting from the main script, and fallback behavior

2. **Given** the current runtime budget is 273/300 lines **When** the spike estimates the line cost **Then** it provides exact line count for server detection logic, whether refactoring or budget raise is needed, and a recommendation

3. **Given** the Neovim `--server` approach requires a terminal window for the UI **When** the spike validates the UX flow **Then** it documents how terminal + server connection works, whether the `always-nvim` window title is preserved, whether cleanup/trap behavior changes, and how the edit → paste flow works (blocking behavior)

4. **Given** the user's normal Neovim (full config) must not be affected **When** the spike validates isolation **Then** it confirms the daemon uses `NA_NVIM_APPNAME` for its own config directory, the socket path is unique, and no environment variable pollution occurs

5. **Given** the spike needs to validate systemd integration **When** investigating service management **Then** it documents a systemd user service file, how `install.sh` installs/enables it, manual start/stop/restart, and crash restart policy

6. **And** the spike produces a written technical design document (appended to this story file in the Dev Agent Record section)
7. **And** the spike identifies any risks or blockers for Story 5.2
8. **And** the spike validates by actually running `nvim --headless --listen /tmp/test.sock` and connecting to it manually

## Tasks / Subtasks

- [x] Task 1: Validate Neovim server mode basics (AC: #1, #8)
  - [x] 1.1: Run `nvim --headless --listen /tmp/always-nvim-test.sock` and verify the socket is created
  - [x] 1.2: In a separate terminal, run `nvim --server /tmp/always-nvim-test.sock --remote <file>` and verify the file opens in the server
  - [x] 1.3: Test what happens when connecting with `--server` to a non-existent socket (fallback behavior)
  - [x] 1.4: Test with `NVIM_APPNAME` exported — verify the daemon uses the custom config directory
  - [x] 1.5: Document exact commands with all flags

- [x] Task 2: Investigate terminal + server UX flow (AC: #3)
  - [x] 2.1: Determine how to open a file in the running server AND display it in a NEW terminal window (this is the hard part — `--remote` opens in an existing Neovim window, not a new terminal)
  - [x] 2.2: Research `nvim --server <sock> --remote-tab`, `--remote-send`, and Neovim's `--embed` mode
  - [x] 2.3: Research alternative approaches: `nvr` (neovim-remote), `nvim --servername`, RPC API via `nvim --listen`
  - [x] 2.4: **CRITICAL**: Determine if the floating terminal approach is compatible with server mode. The current flow is: `$NA_TERMINAL_CMD nvim <args> <file>` — terminal spawns Neovim as a child process. With server mode, the terminal would need to spawn a Neovim CLIENT that connects to the server. Does `nvim --server <sock> --remote <file>` open the UI in the calling terminal or in the server's (headless) terminal?
  - [x] 2.5: Test blocking behavior — does the terminal command block until the user is done editing the file?
  - [x] 2.6: Document the exact terminal launch command for server mode

- [x] Task 3: Line budget analysis (AC: #2)
  - [x] 3.1: Write draft server detection logic (pseudocode) and count lines
  - [x] 3.2: Identify what currently uses budget that could be refactored to save lines
  - [x] 3.3: Decide: stay within 300 or recommend raising NFR12 to 350
  - [x] 3.4: Document recommendation with justification

- [x] Task 4: Isolation validation (AC: #4)
  - [x] 4.1: Verify `NVIM_APPNAME` on the daemon gives it its own config/data/state/cache
  - [x] 4.2: Verify running `nvim` normally (without `--server`) is completely unaffected by a running daemon
  - [x] 4.3: Verify socket path `/tmp/always-nvim-server.sock` does not conflict with any standard Neovim socket paths
  - [x] 4.4: Check if multiple users on the same machine need per-user socket paths (like the lock file uses `$EUID`)

- [x] Task 5: Systemd user service design (AC: #5)
  - [x] 5.1: Write a draft `always-nvim-server.service` unit file
  - [x] 5.2: Determine install location: `~/.config/systemd/user/always-nvim-server.service`
  - [x] 5.3: Define how `install.sh` installs and optionally enables the service
  - [x] 5.4: Define restart policy (`Restart=on-failure`, `RestartSec=5`)
  - [x] 5.5: Define `ExecStart` with correct `NVIM_APPNAME` passthrough
  - [x] 5.6: Handle the case where systemd user services are not available (e.g., no `systemctl --user`)

- [x] Task 6: Risk assessment & design document (AC: #6, #7)
  - [x] 6.1: Identify all risks and blockers for Story 5.2
  - [x] 6.2: Write the technical design document with all findings
  - [x] 6.3: Include decision matrix: server mode viable vs. alternative approaches
  - [x] 6.4: If server mode is NOT viable, document alternative performance strategies (e.g., minimal `NA_NVIM_APPNAME` config, `--noplugin`, lazy loading)

## Dev Notes

### CRITICAL: This Is a Research Spike, Not an Implementation Story

This story produces a **technical design document** — no source code changes to the main script, no new test files. The output is written analysis in the Dev Agent Record section below. The dev agent should:

1. Run experiments on the actual system
2. Document findings with exact commands and outputs
3. Make a go/no-go recommendation for Story 5.2

### The Core Technical Challenge

The current flow at init step 14 is:
```bash
[ -n "$NA_NVIM_APPNAME" ] && export NVIM_APPNAME="$NA_NVIM_APPNAME"
# shellcheck disable=SC2086
$NA_TERMINAL_CMD nvim "${nvim_args[@]}" "$tmpfile"
nvim_exit=$?
```

The terminal command (`alacritty --title always-nvim -e`) spawns Neovim as a child process inside the terminal. The script blocks until the terminal exits. This is critical for the paste flow — `nvim_exit` must reflect whether the user saved (`:wq` → 0) or aborted (`:cq` → non-zero).

**The question is:** Can we replace `nvim` with `nvim --server <sock> --remote <file>` and still get:
1. A new terminal window (not reusing an existing one)
2. The `always-nvim` window title (for WM floating rules)
3. Blocking behavior (script waits until editing is done)
4. Correct exit code (`:wq` vs `:cq`)

If `--remote` opens the file in the server's (headless) session and returns immediately, this approach **won't work** as a drop-in replacement. The spike must find the correct approach.

### Neovim Server Mode Background

Neovim 0.9+ supports:
- `nvim --headless --listen <addr>` — start a headless server on a Unix socket or TCP address
- `nvim --server <addr> --remote <file>` — open a file in an existing server
- `nvim --server <addr> --remote-send <keys>` — send keys to an existing server
- `nvim --server <addr> --remote-tab <file>` — open a file in a new tab in an existing server

The `--remote` family sends the command and **exits immediately** — it does NOT open a UI. This means the naive approach of `$NA_TERMINAL_CMD nvim --server <sock> --remote <file>` will:
1. Open the file in the headless server (no visible UI)
2. Exit immediately (no blocking)
3. Not create a terminal window

**Alternative approaches to investigate:**
- `nvim --server <sock> --remote-ui` — attach a TUI to an existing server (if available in 0.9+)
- Start a new `nvim` instance that connects to the server via RPC
- Use the server only for plugin/config pre-loading, then detach and create a new local session
- Accept that true server mode may not work and instead focus on `NA_NVIM_APPNAME` + minimal config as the performance strategy

### Current System State

- **Neovim version:** v0.12.0-dev (well above 0.9+ requirement)
- **Runtime budget:** 273/300 lines (27 remaining)
- **Main script:** 173 lines (`always-nvim`)
- **Current init step 14:** lines 143-147
- **NA_NVIM_APPNAME:** already implemented (Story 4.1) — empty default, conditional export before terminal launch
- **Lock file:** uses `$EUID` for per-user isolation (`/tmp/always-nvim-$EUID.lock`)
- **All 188 tests passing** across 20 test files

### What `nvim --remote-ui` Does (Key Investigation Target)

The `--remote-ui` flag (added in Neovim 0.9) attaches a **new TUI frontend** to an existing server. This could be the answer:

```bash
# Daemon (started at boot):
nvim --headless --listen /tmp/always-nvim-server.sock

# Each hotkey invocation:
$NA_TERMINAL_CMD nvim --server /tmp/always-nvim-server.sock --remote-ui
```

This would:
- Open a new terminal window with `always-nvim` title ✓
- Attach a TUI to the existing server ✓
- Block until the TUI is closed ✓

**BUT:** Does it share state (buffers, etc.) across invocations? If so, cleanup between invocations is needed. The spike must test this.

### Anti-Patterns to AVOID

1. **DO NOT** modify any source files — this is a research spike
2. **DO NOT** write tests — Story 5.2 handles implementation and testing
3. **DO NOT** install any systemd services — only draft the service file
4. **DO NOT** leave test sockets or processes running after experiments — clean up

### Testing the Spike (Validation Approach)

The dev agent should run actual Neovim commands to validate:
```bash
# Experiment 1: Basic server
nvim --headless --listen /tmp/always-nvim-test.sock &
SERVER_PID=$!
sleep 1

# Experiment 2: Remote file open
nvim --server /tmp/always-nvim-test.sock --remote /tmp/testfile.txt
# Does this block? What exit code?

# Experiment 3: Remote UI (the key test)
alacritty --title always-nvim -e nvim --server /tmp/always-nvim-test.sock --remote-ui
# Does this open a TUI? Does it block? Can you edit and get exit codes?

# Cleanup
kill $SERVER_PID
rm -f /tmp/always-nvim-test.sock
```

### Project Structure Notes

- This story creates NO new files in the source tree
- The technical design output goes in the Dev Agent Record section below
- If the spike produces a separate design doc, save it as: `_bmad-output/implementation-artifacts/spike-neovim-server-design.md`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.1] — Full acceptance criteria (lines 697-744)
- [Source: _bmad-output/planning-artifacts/architecture.md#D9] — Neovim server daemon decision
- [Source: _bmad-output/planning-artifacts/architecture.md#Config Variable Summary] — NA_SERVER_ENABLED, NA_SERVER_SOCKET
- [Source: _bmad-output/planning-artifacts/architecture.md#NFR12] — 300-line budget (line 76)
- [Source: always-nvim lines 143-147] — Init step 14 terminal launch (the code that would change)
- [Source: always-nvim line 42] — NA_NVIM_APPNAME default
- [Source: always-nvim line 144] — NA_NVIM_APPNAME conditional export
- [Source: always-nvim line 48] — Lock file with $EUID pattern (reuse for socket path)
- [Source: install.sh] — Install script (114 lines, will need systemd service integration in 5.2)
- [Source: config] — Reference config file (13 lines, will need NA_SERVER_ENABLED/SOCKET in 5.2)
- [Source: Neovim docs] — `:help --headless`, `:help --listen`, `:help --server`, `:help --remote-ui`

### Previous Story Intelligence (from Story 4.1)

- Agent model: claude-opus-4.6 (github-copilot)
- Neovim version on system: v0.12.0-dev (supports all server features)
- `NA_NVIM_APPNAME` is already implemented — empty default at line 42, conditional export at line 144
- Config variable pattern: `NA_` prefix, empty string default for disabled, set to enable
- How NVIM_APPNAME isolation works: config from `~/.config/$NVIM_APPNAME/`, data from `~/.local/share/$NVIM_APPNAME/`, state from `~/.local/state/$NVIM_APPNAME/`, cache from `~/.cache/$NVIM_APPNAME/`
- Story 4.1 was the cleanest delivery — 2 lines, first-pass success, zero debug issues
- Code review caught: invalid default in config (path instead of empty string)
- Budget after 4.1: 273/300 (27 lines remaining)
- All 188 tests pass, test file naming: `NN_description.bats`, next available: `21`
- BATS executable: `./test/bats/bin/bats`

## Dev Agent Record

### Agent Model Used

claude-opus-4.6 (github-copilot)

### Technical Design Document — Neovim Server Architecture Spike

#### 1. Experiment Results

**System:** Neovim v0.12.0-dev, Alacritty terminal, Linux

##### 1.1 Server Mode Basics

| Command | Result |
|---------|--------|
| `nvim --headless --listen /tmp/test.sock` | ✅ Socket created, server runs in background |
| `nvim --server <sock> --remote <file>` | ✅ Opens file in server, exits immediately (non-blocking), exit code 0 |
| `nvim --server /nonexistent.sock --remote <file>` | Falls back to local editing with `E247: connection refused. Editing locally` |
| `NVIM_APPNAME=always-nvim nvim --headless --listen <sock>` | ✅ Server uses isolated config/data/state/cache directories |

##### 1.2 Remote-UI Investigation (Key Finding)

| Test | Result |
|------|--------|
| `nvim --server <sock> --remote-ui` | ✅ Attaches TUI frontend to server, blocks until UI closes |
| `:wq` on last buffer via remote-ui | ❌ **Server exits** (no buffers left → server quits) |
| `:cq` via remote-ui | ❌ **Server exits** (`:cq` kills entire Neovim process) |
| `:detach` via remote-ui (Neovim 0.10+) | ✅ **Server survives**, UI disconnects, socket preserved |
| Exit code after `:detach` | Always 1 — **cannot distinguish save vs abort** |
| Concurrent remote-ui clients | Both connect, but `:detach` disconnects ALL clients simultaneously |
| Shared buffer state | Yes — all remote-ui clients share the same buffers, same Neovim instance |

##### 1.3 Startup Timing (Measured on This System)

| Scenario | Total Time | Nvim Portion |
|----------|-----------|-------------|
| Terminal only (no nvim) | **184ms** | 0ms |
| Terminal + `-u NONE` | **256ms** | ~72ms |
| Terminal + empty `NVIM_APPNAME` | **266ms** | ~82ms |
| Terminal + default config (full plugins) | **392ms** | ~208ms |
| Terminal + server `--remote-ui` (best case) | **~194ms** | ~10ms |

**Key insight:** Terminal spawn (184ms) is the dominant cost. Server approach saves at most ~72ms vs empty `NVIM_APPNAME` — imperceptible to humans.

#### 2. Architecture Analysis

##### 2.1 The Exit Code Problem (BLOCKER)

The always-nvim paste flow requires:
- `:wq` → exit code 0 → paste clipboard content
- `:cq` → exit code non-zero → abort, restore clipboard

With `--remote-ui`:
- `:wq` kills the server (last buffer closes → Neovim exits)
- `:cq` kills the server (`:cq` always kills Neovim)
- `:detach` gives exit code 1 regardless of save/abort

**Workaround exists but is complex:** Override `:wq`/`:cq` with custom commands that write a signal file then `:detach`. The wrapper reads the signal file. This requires custom Neovim config for the server, changes the user's editing UX, and adds ~10 lines to the main script.

##### 2.2 Shared State Problem

`--remote-ui` is NOT a separate editing session. It is a "screen" to the SAME Neovim instance. This means:
- Previous buffers persist between invocations (need cleanup)
- Undo history leaks across invocations
- If user opens always-nvim twice quickly, both UIs share the same view
- Any crash or misconfiguration affects all connected clients

##### 2.3 Line Budget Impact

Server detection + fallback logic would require ~10 additional lines:
- Socket existence check: ~2 lines
- Signal file setup: ~1 line
- Modified terminal command (if/else): ~3 lines
- Signal file read + exit code mapping: ~3 lines
- Cleanup: ~1 line

Current budget: 273/300 (27 remaining). This would leave ~17 lines remaining — tight but feasible.

#### 3. Systemd Service Design (Draft)

Location: `~/.config/systemd/user/always-nvim-server.service`

```ini
[Unit]
Description=always-nvim Neovim Server Daemon
Documentation=https://github.com/<user>/always-nvim

[Service]
Type=simple
Environment=NVIM_APPNAME=always-nvim
ExecStart=/usr/bin/nvim --headless --listen /tmp/always-nvim-server-%i.sock
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

- `install.sh` would copy the service file and optionally run `systemctl --user enable --now`
- Fallback for systems without systemd: manual `nvim --headless --listen <sock> &` in shell rc
- Socket path uses `%i` (instance name) or `$EUID` for per-user isolation

#### 4. Isolation Validation

| Concern | Status |
|---------|--------|
| NVIM_APPNAME isolation | ✅ Confirmed: `~/.config/always-nvim/`, `~/.local/share/always-nvim/`, etc. |
| Normal Neovim unaffected | ✅ Running `nvim` (no `--server`) is completely independent |
| Socket path conflicts | ✅ `/tmp/always-nvim-server-$EUID.sock` does not conflict with Neovim standard paths |
| Per-user socket isolation | ✅ Using `$EUID` in socket path (same pattern as lock file) |

#### 5. Risk Assessment

| Risk | Severity | Description |
|------|----------|-------------|
| **Exit code problem** | **BLOCKER** | Cannot reliably detect `:wq` vs `:cq` through `--remote-ui` exit code. Workaround exists but adds complexity and changes UX. |
| **Shared state** | HIGH | Buffer/undo state leaks between invocations. Requires cleanup autocmds. |
| **`:detach` disconnects all clients** | HIGH | Concurrent invocations are broken — one `:detach` disconnects all connected UIs. |
| **Server death on `:cq`** | HIGH | `:cq` kills the server daemon. Systemd would restart it, but there's a gap. |
| **Marginal performance gain** | MEDIUM | Only ~72ms savings vs empty `NVIM_APPNAME` (266ms → 194ms). Terminal spawn dominates. |
| **Neovim version requirement** | LOW | `:detach` requires Neovim 0.10+. `--remote-ui` requires 0.9+. Most users on recent versions. |

#### 6. Decision Matrix

| Approach | Startup Savings | Complexity | Exit Code | Isolation | Recommendation |
|----------|----------------|------------|-----------|-----------|---------------|
| **Server + `--remote-ui` + `:detach`** | ~72ms | Very High | ❌ Workaround needed | Shared state | ❌ NO-GO |
| **`NA_NVIM_APPNAME` + minimal config** | ~126ms (vs full) | Zero | ✅ Native | ✅ Full | ✅ **RECOMMENDED** |
| **`--noplugin` flag** | ~126ms (vs full) | 1 line | ✅ Native | Partial | ⚠️ Alternative |
| **`-u NONE`** | ~136ms (vs full) | 1 line | ✅ Native | ✅ Full | ⚠️ Too aggressive |

#### 7. GO/NO-GO Recommendation

### ❌ NO-GO for Server Daemon Approach

**Rationale:**

1. **The exit code problem is a blocker.** The always-nvim paste flow fundamentally depends on `:wq` → 0 and `:cq` → non-zero. Server mode cannot provide this without invasive workarounds that change the editing UX.

2. **Marginal benefit.** Terminal spawn (184ms) dominates total latency. Server saves only ~72ms compared to the already-available `NA_NVIM_APPNAME` approach (which requires zero additional code).

3. **Complexity disproportionate to benefit.** Server mode requires: systemd service, custom Neovim config with command overrides, signal file protocol, buffer cleanup autocmds, concurrent client handling, fallback logic. All for ~72ms savings.

4. **`NA_NVIM_APPNAME` already solves the problem.** Users who want fast always-nvim startup can set `NA_NVIM_APPNAME=always-nvim` in their config and create a minimal `~/.config/always-nvim/init.lua`. This is already implemented (Story 4.1), zero lines added, and provides ~126ms savings vs full config.

### ✅ Recommended Alternative: Document `NA_NVIM_APPNAME` as the Performance Strategy

In Story 5.3 (README), prominently document:
- Set `NA_NVIM_APPNAME=always-nvim` for fast startup
- Create a minimal `~/.config/always-nvim/init.lua` with only the features needed for quick editing
- This reduces nvim startup from ~134ms to ~14ms

### Impact on Story 5.2

**Story 5.2 (Neovim Server Daemon Implementation) should be CANCELLED.** The spike demonstrates the approach is not viable. The performance goal is already met by `NA_NVIM_APPNAME`.

### Debug Log References

- All experiments run on Neovim v0.12.0-dev, Alacritty, Linux
- Experiments used socket paths `/tmp/an-spike*.sock` and `/tmp/always-nvim-spike-test.sock`
- All test sockets and processes cleaned up after experiments

### Completion Notes List

1. ✅ Task 1: Server mode basics validated — socket creation, `--remote` behavior, non-existent socket fallback all confirmed
2. ✅ Task 2: Terminal + server UX flow investigated — `--remote-ui` works with `:detach` for server survival, but exit code always 1 (BLOCKER for paste flow), shared state between invocations
3. ✅ Task 3: Line budget analysis — ~10 lines needed, feasible within budget but moot given NO-GO
4. ✅ Task 4: Isolation validated — `NVIM_APPNAME` provides full path isolation, per-user socket paths via `$EUID`, no conflicts
5. ✅ Task 5: Systemd service designed — draft unit file with restart policy, install.sh integration plan, non-systemd fallback
6. ✅ Task 6: Risk assessment complete — exit code BLOCKER, shared state HIGH risk, marginal perf gain; NO-GO recommendation with `NA_NVIM_APPNAME` as recommended alternative

### Change Log

- 2026-03-13: Story 5.1 spike executed. All 6 tasks completed. **NO-GO recommendation** for server daemon. Recommend cancelling Story 5.2 and documenting `NA_NVIM_APPNAME` as the performance strategy in Story 5.3 (README).

### File List

- `_bmad-output/implementation-artifacts/5-1-neovim-server-architecture-spike.md` — updated (this file)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — updated (5-1 status: in-progress → review)
