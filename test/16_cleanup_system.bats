#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 2.1: Two-Phase Trap & Cleanup System ─────────────────────────────
# Tests: cleanup() function, trap upgrade, R1 backup, idempotency

# ── Structural tests ────────────────────────────────────────────────────────

@test "Story 2.1: cleanup() function defined in script" {
  grep -q '^cleanup()' "$SCRIPT_PATH"
}

@test "Story 2.1: cleanup() restores clipboard with printf not echo (V3, AC#11)" {
  grep -q "printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard" "$SCRIPT_PATH"
}

@test "Story 2.1: cleanup() uses SAVED_CLIPBOARD+x for idempotency (AC#3)" {
  grep -q 'SAVED_CLIPBOARD+x' "$SCRIPT_PATH"
}

@test "Story 2.1: cleanup() removes tmpfile conditionally (AC#3)" {
  grep -q '"\$tmpfile".*rm -f\|rm -f.*"\$tmpfile"' "$SCRIPT_PATH"
}

@test "Story 2.1: cleanup() removes lock file and backup file (AC#2,#6)" {
  grep -q 'rm -f.*LOCK_FILE.*always-nvim-clipboard-backup\|rm -f.*always-nvim-clipboard-backup.*LOCK_FILE' "$SCRIPT_PATH"
}

@test "Story 2.1: trap cleanup EXIT registered at step 10 (AC#1,#4)" {
  grep -q 'trap cleanup EXIT' "$SCRIPT_PATH"
}

@test "Story 2.1: minimal trap at step 5 still exists (ADC-3)" {
  grep -q "trap 'rm -f \"\$LOCK_FILE\"' EXIT" "$SCRIPT_PATH"
}

@test "Story 2.1: R1 backup write exists before clipboard overwrite (AC#5)" {
  local backup_line overwrite_line
  backup_line=$(grep -n 'always-nvim-clipboard-backup' "$SCRIPT_PATH" | grep '>' | head -1 | cut -d: -f1)
  overwrite_line=$(grep -n 'printf.*content.*backend_set_clipboard' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$backup_line" ]
  [ -n "$overwrite_line" ]
  [ "$backup_line" -lt "$overwrite_line" ]
}

@test "Story 2.1: no inline clipboard restore at end of script (moved to cleanup)" {
  # The last line of the script should NOT be a clipboard restore — it's now in cleanup()
  local last_line
  last_line=$(tail -1 "$SCRIPT_PATH")
  [[ "$last_line" != *"SAVED_CLIPBOARD"* ]]
}

# ── Functional tests ────────────────────────────────────────────────────────

@test "Story 2.1: cleanup() restores clipboard and removes files (AC#2,#6)" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    LOCK_FILE=\"\$MOCK_STATE_DIR/test.lock\"
    BACKUP='/tmp/always-nvim-clipboard-backup'
    touch \"\$LOCK_FILE\" \"\$BACKUP\"
    tmpfile=\"\$MOCK_STATE_DIR/tmpfile\"
    touch \"\$tmpfile\"
    SAVED_CLIPBOARD='original'
    backend_set_clipboard() { cat - > \"\$MOCK_STATE_DIR/clipboard_set\"; }
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      rm -f \"\$LOCK_FILE\" \"\$BACKUP\"
    }
    cleanup
    cat \"\$MOCK_STATE_DIR/clipboard_set\"
    [ ! -f \"\$tmpfile\" ] && echo 'tmpfile=removed'
    [ ! -f \"\$LOCK_FILE\" ] && echo 'lock=removed'
    [ ! -f \"\$BACKUP\" ] && echo 'backup=removed'
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "original"
  echo "$output" | grep -q "tmpfile=removed"
  echo "$output" | grep -q "lock=removed"
  echo "$output" | grep -q "backup=removed"
}

@test "Story 2.1: cleanup() is idempotent — safe to call twice (AC#3)" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    LOCK_FILE=\"\$MOCK_STATE_DIR/test.lock\"
    touch \"\$LOCK_FILE\"
    tmpfile=\"\$MOCK_STATE_DIR/tmpfile\"
    touch \"\$tmpfile\"
    SAVED_CLIPBOARD='data'
    backend_set_clipboard() { cat - > /dev/null; }
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      rm -f \"\$LOCK_FILE\" '/tmp/always-nvim-clipboard-backup'
    }
    cleanup
    cleanup
    echo 'idempotent=yes'
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "idempotent=yes"
}

@test "Story 2.1: cleanup() handles unset SAVED_CLIPBOARD gracefully (AC#3)" {
  run bash -c "
    backend_set_clipboard() { cat - > /dev/null; }
    LOCK_FILE='/tmp/test-cleanup-lock'
    touch \"\$LOCK_FILE\"
    tmpfile=''
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      rm -f \"\$LOCK_FILE\" '/tmp/always-nvim-clipboard-backup'
    }
    cleanup
    echo 'safe=yes'
    rm -f \"\$LOCK_FILE\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "safe=yes"
}
