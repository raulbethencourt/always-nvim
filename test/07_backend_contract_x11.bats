#!/usr/bin/env bats

load test_helper

setup() {
  # Create mock directory and tools
  MOCK_DIR=$(mktemp -d)
  export LOG_FILE="$MOCK_DIR/mock_log"
  export PATH="$MOCK_DIR:$PATH"

  # Mock xclip
  cat >"$MOCK_DIR/xclip" <<'EOF'
#!/bin/bash
echo "xclip $*" >> "$LOG_FILE"
if [[ "$*" == *"-o"* ]]; then
    if [[ "$*" == *"primary"* ]]; then
        echo "mock_selection"
    elif [[ "$*" == *"clipboard"* ]]; then
        echo "mock_clipboard"
    fi
else
    # Read stdin for set to consume it
    cat - > /dev/null
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

  # Source the backend
  source "$PROJECT_ROOT/backends/x11.sh"
}

teardown() {
  rm -rf "$MOCK_DIR"
}

@test "Story 1.2: backend_get_selection calls xclip correctly" {
  run backend_get_selection
  [ "$status" -eq 0 ]
  [ "$output" = "mock_selection" ]
  grep -q "xclip -o -selection primary" "$LOG_FILE"
}

@test "Story 1.2: backend_get_clipboard calls xclip correctly" {
  run backend_get_clipboard
  [ "$status" -eq 0 ]
  [ "$output" = "mock_clipboard" ]
  grep -q "xclip -o -selection clipboard" "$LOG_FILE"
}

@test "Story 1.2: backend_set_clipboard calls xclip correctly" {
  echo "new_content" | backend_set_clipboard
  grep -q "xclip -selection clipboard -i" "$LOG_FILE"
}

@test "Story 1.2: backend_simulate_paste calls xdotool correctly" {
  backend_simulate_paste
  grep -q "xdotool key --clearmodifiers ctrl+v" "$LOG_FILE"
}

@test "Story 1.2: backend_get_active_window returns window ID" {
  run backend_get_active_window
  [ "$status" -eq 0 ]
  [ "$output" = "12345" ]
  grep -q "xdotool getactivewindow" "$LOG_FILE"
}

@test "Story 1.2: backend_refocus_window calls xdotool correctly" {
  backend_refocus_window "12345"
  grep -q "xdotool windowactivate 12345" "$LOG_FILE"
}
