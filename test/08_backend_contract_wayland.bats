#!/usr/bin/env bats

load test_helper

setup() {
  MOCK_DIR=$(mktemp -d)
  export LOG_FILE="$MOCK_DIR/mock_log"
  export PATH="$MOCK_DIR:$PATH"

  # Mock wl-paste
  cat >"$MOCK_DIR/wl-paste" <<'MOCK'
#!/bin/bash
echo "wl-paste $*" >> "$LOG_FILE"
if [[ "$*" == *"--primary"* ]]; then
    echo -n "mock_selection"
elif [[ "$*" == *"--no-newline"* ]]; then
    echo -n "mock_clipboard"
fi
MOCK
  chmod +x "$MOCK_DIR/wl-paste"

  # Mock wl-copy
  cat >"$MOCK_DIR/wl-copy" <<'MOCK'
#!/bin/bash
echo "wl-copy $*" >> "$LOG_FILE"
cat - > /dev/null
MOCK
  chmod +x "$MOCK_DIR/wl-copy"

  # Mock wtype
  cat >"$MOCK_DIR/wtype" <<'MOCK'
#!/bin/bash
echo "wtype $*" >> "$LOG_FILE"
MOCK
  chmod +x "$MOCK_DIR/wtype"

  # Mock hyprctl — default: return valid window
  cat >"$MOCK_DIR/hyprctl" <<'MOCK'
#!/bin/bash
echo "hyprctl $*" >> "$LOG_FILE"
if [[ "$*" == *"activewindow -j"* ]]; then
    echo '{"address":"0x5678abcd","title":"test"}'
elif [[ "$*" == *"dispatch"* ]]; then
    true
fi
MOCK
  chmod +x "$MOCK_DIR/hyprctl"

  # Mock jq
  cat >"$MOCK_DIR/jq" <<'MOCK'
#!/bin/bash
echo "jq $*" >> "$LOG_FILE"
# Read stdin
input=$(cat -)
if [[ "$*" == *".address"* ]]; then
    # Extract address from JSON — simple parse
    addr=$(echo "$input" | sed -n 's/.*"address":"\([^"]*\)".*/\1/p')
    echo "$addr"
fi
MOCK
  chmod +x "$MOCK_DIR/jq"

  source "$PROJECT_ROOT/backends/wayland.sh"
}

teardown() {
  rm -rf "$MOCK_DIR"
}

@test "Story 1.3: backend_get_selection calls wl-paste --primary" {
  run backend_get_selection
  [ "$status" -eq 0 ]
  [ "$output" = "mock_selection" ]
  grep -q "wl-paste --primary --no-newline" "$LOG_FILE"
}

@test "Story 1.3: backend_get_selection returns exit 0 on empty (V1)" {
  # Override wl-paste to simulate empty selection (exit 1)
  cat >"$MOCK_DIR/wl-paste" <<'MOCK'
#!/bin/bash
exit 1
MOCK
  chmod +x "$MOCK_DIR/wl-paste"

  run backend_get_selection
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Story 1.3: backend_get_clipboard calls wl-paste" {
  run backend_get_clipboard
  [ "$status" -eq 0 ]
  [ "$output" = "mock_clipboard" ]
  grep -q "wl-paste --no-newline" "$LOG_FILE"
}

@test "Story 1.3: backend_get_clipboard returns exit 0 on empty (V2)" {
  cat >"$MOCK_DIR/wl-paste" <<'MOCK'
#!/bin/bash
exit 1
MOCK
  chmod +x "$MOCK_DIR/wl-paste"

  run backend_get_clipboard
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Story 1.3: backend_set_clipboard calls wl-copy" {
  echo "new_content" | backend_set_clipboard
  grep -q "wl-copy" "$LOG_FILE"
}

@test "Story 1.3: backend_simulate_paste calls wtype correctly" {
  backend_simulate_paste
  grep -q "wtype -M ctrl -k v -m ctrl" "$LOG_FILE"
}

@test "Story 1.3: backend_get_active_window returns address" {
  run backend_get_active_window
  [ "$status" -eq 0 ]
  [ "$output" = "0x5678abcd" ]
  grep -q "hyprctl activewindow -j" "$LOG_FILE"
}

@test "Story 1.3: backend_get_active_window returns exit 1 on null address (V4)" {
  # Override hyprctl to return null address
  cat >"$MOCK_DIR/hyprctl" <<'MOCK'
#!/bin/bash
echo '{"address":"0x0","title":"none"}'
MOCK
  chmod +x "$MOCK_DIR/hyprctl"

  # Override jq to return 0x0
  cat >"$MOCK_DIR/jq" <<'MOCK'
#!/bin/bash
input=$(cat -)
echo "0x0"
MOCK
  chmod +x "$MOCK_DIR/jq"

  run backend_get_active_window
  [ "$status" -eq 1 ]
}

@test "Story 1.3: backend_get_active_window returns exit 1 on 'null' address (V4)" {
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

@test "Story 1.3: backend_refocus_window calls hyprctl dispatch" {
  backend_refocus_window "0x5678abcd"
  grep -q "hyprctl dispatch focuswindow address:0x5678abcd" "$LOG_FILE"
}

@test "Story 1.3: wayland backend under 50 lines excluding comments" {
  local line_count
  line_count=$(grep -v '^\s*#' "$PROJECT_ROOT/backends/wayland.sh" | grep -cv '^\s*$')
  [ "$line_count" -le 50 ]
}
