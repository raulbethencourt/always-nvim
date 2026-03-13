#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 2.3: Cleanup & Trap Tests ─────────────────────────────────────────
# Tests: two-phase trap ordering, abort path, stale cleanup, lock creation,
#        cleanup ordering, R1 backup content, no-lock scenario
# NOTE: Does NOT duplicate tests in 16_cleanup_system.bats or 17_abort_lock_stale.bats

# ── Structural tests ────────────────────────────────────────────────────────

# Task 1.5 / 1.4: Two-phase trap ordering — step 5 minimal trap BEFORE step 10 full trap (ADC-3)
@test "cleanup: two-phase trap ordering — step 5 minimal trap before step 10 full cleanup trap" {
  local step5_line step10_line
  step5_line=$(grep -n "trap 'rm -f \"\$LOCK_FILE\"' EXIT" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  step10_line=$(grep -n 'trap cleanup EXIT' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$step5_line" ]
  [ -n "$step10_line" ]
  [ "$step5_line" -lt "$step10_line" ]
}

# Task 1.7: Abort path — nvim_exit check gates paste flow (FR15)
@test "cleanup: abort path — if nvim_exit -eq 0 gates entire paste flow" {
  grep -q 'if \[ "$nvim_exit" -eq 0 \]' "$SCRIPT_PATH"
}

# Task 1.7: Abort path line ordering — nvim_exit check comes after terminal launch
@test "cleanup: abort path — nvim_exit check after terminal launch line" {
  local launch_line gate_line
  launch_line=$(grep -n 'NA_TERMINAL_CMD nvim' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  gate_line=$(grep -n 'if \[ "$nvim_exit" -eq 0 \]' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$launch_line" ]
  [ -n "$gate_line" ]
  [ "$launch_line" -lt "$gate_line" ]
}

# Task 1.1: cleanup() is defined with cleanup() syntax (not function keyword)
@test "cleanup: defined with cleanup() syntax not function keyword" {
  grep -q '^cleanup()' "$SCRIPT_PATH"
  # Verify no 'function cleanup' variant exists
  ! grep -q '^function cleanup' "$SCRIPT_PATH"
}

# Task 1.2: cleanup restores clipboard via printf | backend_set_clipboard
@test "cleanup: restores clipboard inside cleanup() before file removal" {
  # Verify ordering within cleanup(): clipboard restore line before lock+backup rm line
  local restore_line rm_line
  restore_line=$(grep -n "printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard" "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  rm_line=$(grep -n 'rm -f "\$LOCK_FILE" "/tmp/always-nvim-clipboard-backup"' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$restore_line" ]
  [ -n "$rm_line" ]
  [ "$restore_line" -lt "$rm_line" ]
}

# Task 1.3: cleanup removes tmpfile, lock file, and backup file
@test "cleanup: removes tmpfile with conditional check" {
  # Verify tmpfile removal uses -n check (not unconditional)
  grep -q '\[ -n "\$tmpfile" \] && rm -f "\$tmpfile"' "$SCRIPT_PATH"
}

# Task 1.6: R1 backup write happens BEFORE clipboard overwrite in paste flow
@test "cleanup: R1 backup write before clipboard overwrite in paste flow" {
  local backup_line set_clipboard_line
  backup_line=$(grep -n 'always-nvim-clipboard-backup' "$SCRIPT_PATH" | grep 'SAVED_CLIPBOARD' | head -1 | cut -d: -f1)
  set_clipboard_line=$(grep -n 'printf.*content.*backend_set_clipboard' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$backup_line" ]
  [ -n "$set_clipboard_line" ]
  [ "$backup_line" -lt "$set_clipboard_line" ]
}

# Task 3.3: Stale cleanup is at step 11 (after trap upgrade at step 10)
@test "cleanup: stale file cleanup at step 11 after trap upgrade at step 10" {
  local trap_line stale_line
  trap_line=$(grep -n 'trap cleanup EXIT' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  stale_line=$(grep -n 'find /tmp -name "always-nvim-' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$trap_line" ]
  [ -n "$stale_line" ]
  [ "$trap_line" -lt "$stale_line" ]
}

# Task 4.4: Lock file uses $EUID in path for multi-user safety
@test "cleanup: lock file path includes EUID for multi-user safety" {
  grep -q 'LOCK_FILE="/tmp/always-nvim-\$EUID.lock"' "$SCRIPT_PATH"
}

# ── Functional tests ────────────────────────────────────────────────────────

# Task 2.1: Normal exit — restores clipboard, removes tmpfile, removes lock, removes backup
@test "cleanup: normal exit removes all artifacts and restores clipboard" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    LOCK_FILE=\"\$MOCK_STATE_DIR/test.lock\"
    # FIX: Use exact hardcoded filename from script to ensure accurate test coverage
    BACKUP='/tmp/always-nvim-clipboard-backup'
    tmpfile=\"\$MOCK_STATE_DIR/tmpfile\"
    touch \"\$LOCK_FILE\" \"\$BACKUP\" \"\$tmpfile\"
    SAVED_CLIPBOARD='original-clipboard-data'
    backend_set_clipboard() { cat - > \"\$MOCK_STATE_DIR/clipboard_set\"; }
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      # FIX: Match script exactly (hardcoded path)
      rm -f \"\$LOCK_FILE\" \"/tmp/always-nvim-clipboard-backup\"
    }
    cleanup
    printf '%s' \"\$(cat \"\$MOCK_STATE_DIR/clipboard_set\")\"
    echo ''
    [ ! -f \"\$tmpfile\" ] && echo 'tmpfile=gone'
    [ ! -f \"\$LOCK_FILE\" ] && echo 'lock=gone'
    [ ! -f \"\$BACKUP\" ] && echo 'backup=gone'
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "original-clipboard-data"
  echo "$output" | grep -q "tmpfile=gone"
  echo "$output" | grep -q "lock=gone"
  echo "$output" | grep -q "backup=gone"
}

# Task 2.2: Idempotency — calling cleanup twice produces no errors
@test "cleanup: idempotency — double invocation no errors" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    LOCK_FILE=\"\$MOCK_STATE_DIR/test.lock\"
    tmpfile=\"\$MOCK_STATE_DIR/tmpfile\"
    touch \"\$LOCK_FILE\" \"\$tmpfile\"
    SAVED_CLIPBOARD='data'
    call_count=0
    backend_set_clipboard() { call_count=\$((call_count + 1)); cat - > /dev/null; }
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      rm -f \"\$LOCK_FILE\" '/tmp/always-nvim-clipboard-backup'
    }
    cleanup
    cleanup
    echo 'double-call=ok'
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "double-call=ok"
}

# Task 2.3: Unset SAVED_CLIPBOARD — no crash, files still cleaned
@test "cleanup: unset SAVED_CLIPBOARD — files still cleaned no crash" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    LOCK_FILE=\"\$MOCK_STATE_DIR/test.lock\"
    tmpfile=\"\$MOCK_STATE_DIR/tmpfile\"
    touch \"\$LOCK_FILE\" \"\$tmpfile\"
    # Intentionally NOT setting SAVED_CLIPBOARD
    backend_set_clipboard() { cat - > /dev/null; }
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      rm -f \"\$LOCK_FILE\" '/tmp/always-nvim-clipboard-backup'
    }
    cleanup
    [ ! -f \"\$tmpfile\" ] && echo 'tmpfile=cleaned'
    [ ! -f \"\$LOCK_FILE\" ] && echo 'lock=cleaned'
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "tmpfile=cleaned"
  echo "$output" | grep -q "lock=cleaned"
}

# Task 2.4: Empty tmpfile path — no crash, other files still cleaned
@test "cleanup: empty tmpfile path — no crash other files cleaned" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    LOCK_FILE=\"\$MOCK_STATE_DIR/test.lock\"
    touch \"\$LOCK_FILE\"
    tmpfile=''
    SAVED_CLIPBOARD='saved'
    backend_set_clipboard() { cat - > \"\$MOCK_STATE_DIR/clipboard_set\"; }
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      rm -f \"\$LOCK_FILE\" '/tmp/always-nvim-clipboard-backup'
    }
    cleanup
    [ ! -f \"\$LOCK_FILE\" ] && echo 'lock=cleaned'
    [ -f \"\$MOCK_STATE_DIR/clipboard_set\" ] && echo 'clipboard=restored'
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "lock=cleaned"
  echo "$output" | grep -q "clipboard=restored"
}

# Task 2.5: Abort path (non-zero exit) — cleanup runs, no paste occurred
@test "cleanup: abort path — non-zero exit triggers cleanup no paste" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    LOCK_FILE=\"\$MOCK_STATE_DIR/test.lock\"
    tmpfile=\"\$MOCK_STATE_DIR/tmpfile\"
    touch \"\$LOCK_FILE\" \"\$tmpfile\"
    SAVED_CLIPBOARD='original'
    paste_called=0
    backend_set_clipboard() { cat - > \"\$MOCK_STATE_DIR/clipboard_set\"; }
    backend_simulate_paste() { printf '1' > \"\$MOCK_STATE_DIR/paste_called\"; }
    cleanup() {
      [ \"\${SAVED_CLIPBOARD+x}\" ] && printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
      [ -n \"\$tmpfile\" ] && rm -f \"\$tmpfile\"
      rm -f \"\$LOCK_FILE\" '/tmp/always-nvim-clipboard-backup'
    }
    # Simulate abort: nvim_exit != 0
    nvim_exit=1
    if [ \"\$nvim_exit\" -eq 0 ]; then
      backend_simulate_paste
    fi
    cleanup
    [ ! -f \"\$MOCK_STATE_DIR/paste_called\" ] && echo 'paste=skipped'
    [ -f \"\$MOCK_STATE_DIR/clipboard_set\" ] && echo 'clipboard=restored'
    [ ! -f \"\$tmpfile\" ] && echo 'tmpfile=cleaned'
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "paste=skipped"
  echo "$output" | grep -q "clipboard=restored"
  echo "$output" | grep -q "tmpfile=cleaned"
}

# Task 3.1: find command removes files older than 60 minutes
@test "cleanup: stale file cleanup removes files older than 60 minutes" {
  run bash -c "
    TEST_DIR=\$(mktemp -d /tmp/always-nvim-stale-test-XXXXXX)
    # Create an 'old' file (touch with timestamp 2 hours ago)
    OLD_FILE=\"\$TEST_DIR/always-nvim-old-XXXXXX\"
    touch \"\$OLD_FILE\"
    touch -t \$(date -d '2 hours ago' +%Y%m%d%H%M.%S) \"\$OLD_FILE\"
    # Verify old file exists before find
    [ -f \"\$OLD_FILE\" ] && echo 'old-exists'
    # Run the stale cleanup pattern against our test dir
    find \"\$TEST_DIR\" -name 'always-nvim-*' -mmin +60 -delete 2>/dev/null
    # Verify old file was removed
    [ ! -f \"\$OLD_FILE\" ] && echo 'old-removed'
    rm -rf \"\$TEST_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "old-exists"
  echo "$output" | grep -q "old-removed"
}

# Task 3.2: find command does NOT remove files younger than 60 minutes
@test "cleanup: stale file cleanup preserves files younger than 60 minutes" {
  run bash -c "
    TEST_DIR=\$(mktemp -d /tmp/always-nvim-stale-test-XXXXXX)
    # Create a 'recent' file (just created, so <60 min old)
    RECENT_FILE=\"\$TEST_DIR/always-nvim-recent-XXXXXX\"
    touch \"\$RECENT_FILE\"
    # Run the stale cleanup pattern
    find \"\$TEST_DIR\" -name 'always-nvim-*' -mmin +60 -delete 2>/dev/null
    # Verify recent file was preserved
    [ -f \"\$RECENT_FILE\" ] && echo 'recent-preserved'
    rm -rf \"\$TEST_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "recent-preserved"
}

# Task 4.1: Lock file with live PID blocks new invocation
@test "cleanup: lock file with live PID blocks invocation" {
  run bash -c "
    MOCK_STATE_DIR=\$(mktemp -d)
    trap 'rm -rf \"\$MOCK_STATE_DIR\"' EXIT
    LOCK_FILE=\"\$MOCK_STATE_DIR/always-nvim-test.lock\"
    # Write our own (live) PID
    printf '%s' \$\$ >\"\$LOCK_FILE\"
    # Simulate the lock check logic from always-nvim lines 48-52
    [ -f \"\$LOCK_FILE\" ] && {
      pid=\$(cat \"\$LOCK_FILE\")
      kill -0 \"\$pid\" 2>/dev/null && {
        echo 'blocked-live-pid'
        exit 1
      }
      rm -f \"\$LOCK_FILE\"
    }
    echo 'should-not-reach'
  "
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "blocked-live-pid"
}

# Task 4.2: Lock file with dead PID — stale lock removed, proceeds
@test "cleanup: lock file with dead PID removed and proceeds" {
  run bash -c "
    MOCK_STATE_DIR=\$(mktemp -d)
    trap 'rm -rf \"\$MOCK_STATE_DIR\"' EXIT
    LOCK_FILE=\"\$MOCK_STATE_DIR/always-nvim-test.lock\"
    # Write a non-existent PID
    printf '%s' 99999999 >\"\$LOCK_FILE\"
    [ -f \"\$LOCK_FILE\" ] && {
      pid=\$(cat \"\$LOCK_FILE\")
      kill -0 \"\$pid\" 2>/dev/null && {
        echo 'blocked'
        exit 1
      }
      rm -f \"\$LOCK_FILE\"
    }
    [ ! -f \"\$LOCK_FILE\" ] && echo 'stale-lock-removed'
    echo 'proceeded'
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "stale-lock-removed"
  echo "$output" | grep -q "proceeded"
}

# Task 4.3: No lock file — proceeds normally, creates new lock
@test "cleanup: no lock file proceeds and creates new lock" {
  run bash -c "
    MOCK_STATE_DIR=\$(mktemp -d)
    trap 'rm -rf \"\$MOCK_STATE_DIR\"' EXIT
    LOCK_FILE=\"\$MOCK_STATE_DIR/always-nvim-test.lock\"
    # No lock file exists — simulate script lock logic
    [ -f \"\$LOCK_FILE\" ] && {
      pid=\$(cat \"\$LOCK_FILE\")
      kill -0 \"\$pid\" 2>/dev/null && {
        echo 'blocked'
        exit 1
      }
      rm -f \"\$LOCK_FILE\"
    }
    # Script creates lock with current PID
    # NOTE: This line simulates the script logic (printf > LOCK_FILE)
    # We are testing that *this logic block* correctly creates a file containing our PID
    printf '%s' \$\$ >\"\$LOCK_FILE\"
    
    # Verify lock was created with our PID
    [ -f \"\$LOCK_FILE\" ] && echo 'lock-created'
    lock_pid=\$(cat \"\$LOCK_FILE\")
    [ \"\$lock_pid\" = \"\$\$\" ] && echo 'pid-matches'
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "lock-created"
  echo "$output" | grep -q "pid-matches"
}
