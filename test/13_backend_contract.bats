#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 1.7: Cross-Backend Contract & V1-V4 Regression Tests ─────────────
# Tests: backend parity (same behavior from both backends), V3 trailing newline,
# empty selection/clipboard normalization per error contract (ADC-2)
# NOTE: Does NOT duplicate tests in 07_backend_contract_x11.bats / 08_backend_contract_wayland.bats

# ── Helper: create mock environment for a backend ────────────────────────────

setup_x11_mocks() {
  MOCK_DIR=$(mktemp -d)
  export LOG_FILE="$MOCK_DIR/mock_log"
  export PATH="$MOCK_DIR:$PATH"

  # Default xclip — returns empty (exit 1) for selection/clipboard reads
  cat >"$MOCK_DIR/xclip" <<'EOF'
#!/bin/bash
echo "xclip $*" >> "$LOG_FILE"
if [[ "$*" == *"-o"* ]]; then
    exit 1
else
    cat - > "$LOG_FILE.clipboard_data"
fi
EOF
  chmod +x "$MOCK_DIR/xclip"

  # Mock xdotool
  cat >"$MOCK_DIR/xdotool" <<'EOF'
#!/bin/bash
echo "xdotool $*" >> "$LOG_FILE"
if [[ "$*" == *"getactivewindow"* ]]; then
    echo "12345"
fi
EOF
  chmod +x "$MOCK_DIR/xdotool"

  source "$PROJECT_ROOT/backends/x11.sh"
}

setup_wayland_mocks() {
  MOCK_DIR=$(mktemp -d)
  export LOG_FILE="$MOCK_DIR/mock_log"
  export PATH="$MOCK_DIR:$PATH"

  # Default wl-paste — returns empty (exit 1) for selection/clipboard reads
  cat >"$MOCK_DIR/wl-paste" <<'MOCK'
#!/bin/bash
echo "wl-paste $*" >> "$LOG_FILE"
exit 1
MOCK
  chmod +x "$MOCK_DIR/wl-paste"

  # Mock wl-copy — captures stdin to file
  cat >"$MOCK_DIR/wl-copy" <<'MOCK'
#!/bin/bash
echo "wl-copy $*" >> "$LOG_FILE"
cat - > "$LOG_FILE.clipboard_data"
MOCK
  chmod +x "$MOCK_DIR/wl-copy"

  # Mock wtype
  cat >"$MOCK_DIR/wtype" <<'MOCK'
#!/bin/bash
echo "wtype $*" >> "$LOG_FILE"
MOCK
  chmod +x "$MOCK_DIR/wtype"

  # Mock hyprctl
  cat >"$MOCK_DIR/hyprctl" <<'MOCK'
#!/bin/bash
echo "hyprctl $*" >> "$LOG_FILE"
if [[ "$*" == *"activewindow -j"* ]]; then
    echo '{"address":"0x5678abcd","title":"test"}'
fi
MOCK
  chmod +x "$MOCK_DIR/hyprctl"

  # Mock jq
  cat >"$MOCK_DIR/jq" <<'MOCK'
#!/bin/bash
input=$(cat -)
if [[ "$*" == *".address"* ]]; then
    addr=$(echo "$input" | sed -n 's/.*"address":"\([^"]*\)".*/\1/p')
    echo "$addr"
fi
MOCK
  chmod +x "$MOCK_DIR/jq"

  source "$PROJECT_ROOT/backends/wayland.sh"
}

teardown() {
  [ -n "$MOCK_DIR" ] && rm -rf "$MOCK_DIR"
}

# ── V1: backend_get_selection returns exit 0 + empty on empty selection ──────

@test "contract: X11 backend_get_selection returns exit 0 on empty selection (V1 parity)" {
  setup_x11_mocks

  run backend_get_selection
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "contract: Wayland backend_get_selection returns exit 0 on empty selection (V1 parity)" {
  setup_wayland_mocks

  run backend_get_selection
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── V2: backend_get_clipboard returns exit 0 + empty on empty clipboard ──────

@test "contract: X11 backend_get_clipboard returns exit 0 on empty clipboard (V2 parity)" {
  setup_x11_mocks

  run backend_get_clipboard
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "contract: Wayland backend_get_clipboard returns exit 0 on empty clipboard (V2 parity)" {
  setup_wayland_mocks

  run backend_get_clipboard
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── V3: backend_set_clipboard preserves exact content (no trailing newline) ──

@test "contract: X11 backend_set_clipboard preserves content without trailing newline (V3)" {
  setup_x11_mocks

  printf '%s' "exact content" | backend_set_clipboard
  # Verify the data captured by mock xclip has no trailing newline
  result=$(cat "$LOG_FILE.clipboard_data")
  [ "$result" = "exact content" ]
}

@test "contract: Wayland backend_set_clipboard preserves content without trailing newline (V3)" {
  setup_wayland_mocks

  printf '%s' "exact content" | backend_set_clipboard
  result=$(cat "$LOG_FILE.clipboard_data")
  [ "$result" = "exact content" ]
}

@test "contract: X11 backend_set_clipboard handles multiline without trailing newline (V3)" {
  setup_x11_mocks

  printf '%s' "line1
line2
line3" | backend_set_clipboard
  result=$(cat "$LOG_FILE.clipboard_data")
  # Must NOT have trailing newline
  local byte_count expected_count
  byte_count=$(wc -c <"$LOG_FILE.clipboard_data")
  expected_count=$(printf '%s' "line1
line2
line3" | wc -c)
  [ "$byte_count" -eq "$expected_count" ]
}

@test "contract: Wayland backend_set_clipboard handles multiline without trailing newline (V3)" {
  setup_wayland_mocks

  printf '%s' "line1
line2
line3" | backend_set_clipboard
  result=$(cat "$LOG_FILE.clipboard_data")
  local byte_count expected_count
  byte_count=$(wc -c <"$LOG_FILE.clipboard_data")
  expected_count=$(printf '%s' "line1
line2
line3" | wc -c)
  [ "$byte_count" -eq "$expected_count" ]
}

# ── V4: Wayland backend_get_active_window — null/zero address ────────────────

@test "contract: Wayland backend_get_active_window returns exit 1 on 0x0 address (V4)" {
  setup_wayland_mocks

  # Override hyprctl to return 0x0
  cat >"$MOCK_DIR/hyprctl" <<'MOCK'
#!/bin/bash
echo '{"address":"0x0","title":"none"}'
MOCK
  chmod +x "$MOCK_DIR/hyprctl"

  cat >"$MOCK_DIR/jq" <<'MOCK'
#!/bin/bash
input=$(cat -)
echo "0x0"
MOCK
  chmod +x "$MOCK_DIR/jq"

  run backend_get_active_window
  [ "$status" -eq 1 ]
}

@test "contract: Wayland backend_get_active_window returns exit 1 on null address (V4)" {
  setup_wayland_mocks

  cat >"$MOCK_DIR/hyprctl" <<'MOCK'
#!/bin/bash
echo '{"address":"null","title":"none"}'
MOCK
  chmod +x "$MOCK_DIR/hyprctl"

  cat >"$MOCK_DIR/jq" <<'MOCK'
#!/bin/bash
input=$(cat -)
echo "null"
MOCK
  chmod +x "$MOCK_DIR/jq"

  run backend_get_active_window
  [ "$status" -eq 1 ]
}

@test "contract: Wayland backend_get_active_window returns exit 0 on valid address (V4)" {
  setup_wayland_mocks

  run backend_get_active_window
  [ "$status" -eq 0 ]
  [ "$output" = "0x5678abcd" ]
}

# ── Cross-backend parity: both backends define all 6 functions ───────────────

@test "contract: X11 backend defines all 6 required functions" {
  setup_x11_mocks

  declare -f backend_get_selection >/dev/null
  declare -f backend_get_clipboard >/dev/null
  declare -f backend_set_clipboard >/dev/null
  declare -f backend_simulate_paste >/dev/null
  declare -f backend_get_active_window >/dev/null
  declare -f backend_refocus_window >/dev/null
}

@test "contract: Wayland backend defines all 6 required functions" {
  setup_wayland_mocks

  declare -f backend_get_selection >/dev/null
  declare -f backend_get_clipboard >/dev/null
  declare -f backend_set_clipboard >/dev/null
  declare -f backend_simulate_paste >/dev/null
  declare -f backend_get_active_window >/dev/null
  declare -f backend_refocus_window >/dev/null
}
