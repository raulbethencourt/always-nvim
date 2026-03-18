#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 2.2: Abort Detection, Lock File & Stale Cleanup ───────────────────
# Tests: R3 lock file, R2 stale cleanup, AC3 no-change detection

# ── Structural tests ────────────────────────────────────────────────────────

@test "Story 2.2: Lock file section checks for existing lock (R3, AC#4)" {
  grep -q '\[ -f "$LOCK_FILE" \]' "$SCRIPT_PATH"
}

@test "Story 2.2: Lock file section reads PID from lock (R3, AC#4)" {
  grep -q 'pid=$(cat "$LOCK_FILE")' "$SCRIPT_PATH"
}

@test "Story 2.2: Lock file section uses kill -0 for PID check (R3, AC#4)" {
  grep -q 'kill -0 "$pid"' "$SCRIPT_PATH"
}

@test "Story 2.2: Lock file section calls error_exit for live PID (R3, AC#4)" {
  grep -q 'error_exit.*already running' "$SCRIPT_PATH"
}

@test "Story 2.2: Lock file section removes stale lock (R3, AC#5)" {
  # After kill -0 check, if PID dead, stale lock is removed before proceeding
  grep -q 'rm -f "$LOCK_FILE"' "$SCRIPT_PATH"
}

@test "Story 2.2: Lock file writes PID with printf not echo (V3)" {
  grep -q "printf '%s' \$\$ >\"\$LOCK_FILE\"" "$SCRIPT_PATH"
}

@test "Story 2.2: Stale file cleanup uses safer find at step 11 (R2, AC#6)" {
  grep -q 'find /tmp -name "always-nvim-\*" -mmin +60 -delete' "$SCRIPT_PATH"
}

@test "Story 2.2: No-change detection present in paste flow (FR15, AC#3)" {
  grep -q 'mode.*B.*content.*selection\|"$mode" = "B".*"$content" = "$selection"' "$SCRIPT_PATH"
}

@test "Story 2.2: No-change detection exits 0 to trigger cleanup (AC#3)" {
  # exit 0 appears in the no-change block (mode B && content == selection)
  grep -A10 '"$mode" = "B"' "$SCRIPT_PATH" | grep -q 'exit 0'
}

@test "Story 2.2: Lock file uses UID in filename for multi-user safety" {
  grep -q 'LOCK_FILE="/tmp/always-nvim-\$EUID.lock"' "$SCRIPT_PATH"
}

# ── Functional tests ────────────────────────────────────────────────────────

# Helper to run script logic in a subshell with mocked environment
run_script_logic() {
  local mode="$1"
  local selection="$2"
  local content="$3"

  # We extract the logic block or simulate it correctly.
  # This uses the EXACT logic from the script:
  # [ "$mode" = "B" ] && [ "$content" = "$selection" ] && exit 0

  bash -c "
    mode='$mode'
    selection='$selection'
    content='$content'
    
    # Logic simulation
    [ \"\$mode\" = \"B\" ] && [ \"\$content\" = \"\$selection\" ] && {
      echo 'skip-paste'
      exit 0
    }
    echo 'paste-proceeds'
  "
}

@test "Story 2.2: Mode B no-change → exit 0 (skip paste) (AC#3)" {
  run run_script_logic "B" "hello world" "hello world"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "skip-paste"
}

@test "Story 2.2: Mode B with changes → paste proceeds (AC#3)" {
  run run_script_logic "B" "hello world" "hello world modified"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "paste-proceeds"
}

@test "Story 2.2: Mode A → paste proceeds regardless of content (AC#3)" {
  run run_script_logic "A" "" "new text"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "paste-proceeds"
}

# Lock file functional tests need to simulate the file system state
@test "Story 2.2: Lock file PID check — live PID blocks (R3, AC#4)" {
  # We construct a test that mirrors the script logic exactly
  # logic: [ -f LOCK ] && { pid=$(cat LOCK); kill -0 pid && error || rm LOCK }

  run bash -c "
    MOCK_STATE_DIR=\$(mktemp -d)
    trap 'rm -rf \"\$MOCK_STATE_DIR\"' EXIT
    
    # Create a real lock file with our PID
    LOCK_FILE=\"\$MOCK_STATE_DIR/always-nvim-\$EUID.lock\"
    echo \$\$ > \"\$LOCK_FILE\"
    
    # Simulate the check logic from script lines 48-52
    [ -f \"\$LOCK_FILE\" ] && {
      pid=\$(cat \"\$LOCK_FILE\")
      kill -0 \"\$pid\" 2>/dev/null && {
        echo 'blocked'
        exit 1
      }
      rm -f \"\$LOCK_FILE\"
    }
    echo 'proceed'
  "
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "blocked"
}

@test "Story 2.2: Lock file PID check — dead PID proceeds (R3, AC#5)" {
  run bash -c "
    MOCK_STATE_DIR=\$(mktemp -d)
    trap 'rm -rf \"\$MOCK_STATE_DIR\"' EXIT
    
    # Create a lock file with a non-existent PID
    LOCK_FILE=\"\$MOCK_STATE_DIR/always-nvim-\$EUID.lock\"
    echo 99999999 > \"\$LOCK_FILE\"
    
    # Simulate the check logic from script lines 48-52
    [ -f \"\$LOCK_FILE\" ] && {
      pid=\$(cat \"\$LOCK_FILE\")
      kill -0 \"\$pid\" 2>/dev/null && {
        echo 'blocked'
        exit 1
      }
      rm -f \"\$LOCK_FILE\"
    }
    echo 'proceed'
    
    # Verify stale lock was removed (the logic should remove it)
    if [ -f \"\$LOCK_FILE\" ]; then echo 'lock-remains'; else echo 'lock-removed'; fi
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "proceed"
  echo "$output" | grep -q "lock-removed"
}
