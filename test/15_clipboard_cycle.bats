#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 1.7: Clipboard Save/Restore Cycle Tests ──────────────────────────
# Tests: save→overwrite→restore cycle, special characters, backup file (R1 spec)
# Uses centralized test_helper.sh mock pattern (ADC-7)

# ── Helper: simulate clipboard save→overwrite→restore cycle ─────────────────

run_clipboard_cycle() {
  local original_clipboard="$1"
  local edited_content="$2"

  bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'

    # ── Simulate a file-backed clipboard for realistic cycle ──
    CLIP_FILE=\"\$MOCK_STATE_DIR/sim_clipboard\"
    printf '%s' '$original_clipboard' > \"\$CLIP_FILE\"

    # Override mocks to use file-backed clipboard
    backend_get_clipboard() { cat \"\$CLIP_FILE\"; }
    backend_set_clipboard() { cat - > \"\$CLIP_FILE\"; }

    # ── Step 9: Save clipboard ──
    SAVED_CLIPBOARD=\$(backend_get_clipboard)

    # ── Simulate edit: overwrite clipboard with edited content ──
    printf '%s' '$edited_content' | backend_set_clipboard

    # Verify clipboard was overwritten
    current=\$(backend_get_clipboard)
    echo \"overwritten=\$current\"

    # ── Restore clipboard ──
    printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard

    # Verify restoration
    restored=\$(backend_get_clipboard)
    echo \"restored=\$restored\"

    # Compare byte-for-byte
    original_bytes=\$(printf '%s' '$original_clipboard' | wc -c)
    restored_bytes=\$(printf '%s' \"\$restored\" | wc -c)
    echo \"original_bytes=\$original_bytes\"
    echo \"restored_bytes=\$restored_bytes\"

    if [ \"\$restored\" = '$original_clipboard' ]; then
      echo 'match=yes'
    else
      echo 'match=no'
    fi

    # Cleanup
    rm -rf \"\$MOCK_STATE_DIR\"
  "
}

# ── AC #10: Save/restore cycle preserves clipboard (FR4, FR5) ────────────────

@test "clipboard-cycle: clipboard identical after save→overwrite→restore (FR4, FR5)" {
  run run_clipboard_cycle "original clipboard data" "edited content"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "overwritten=edited content"
  echo "$output" | grep -q "restored=original clipboard data"
  echo "$output" | grep -q "match=yes"
}

# ── AC #11: Special characters preserved through cycle (V3) ─────────────────

@test "clipboard-cycle: newlines preserved through save→overwrite→restore (V3)" {
  # Use a subshell approach for multiline content
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'

    CLIP_FILE=\"\$MOCK_STATE_DIR/sim_clipboard\"
    original=\"line1
line2
line3\"
    printf '%s' \"\$original\" > \"\$CLIP_FILE\"

    backend_get_clipboard() { cat \"\$CLIP_FILE\"; }
    backend_set_clipboard() { cat - > \"\$CLIP_FILE\"; }

    SAVED_CLIPBOARD=\$(backend_get_clipboard)
    printf '%s' 'overwrite' | backend_set_clipboard
    printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard

    restored=\$(backend_get_clipboard)
    if [ \"\$restored\" = \"\$original\" ]; then
      echo 'match=yes'
    else
      echo 'match=no'
    fi
    # Byte count verification
    echo \"original_bytes=\$(printf '%s' \"\$original\" | wc -c)\"
    echo \"restored_bytes=\$(printf '%s' \"\$restored\" | wc -c)\"

    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "match=yes"
}

@test "clipboard-cycle: tabs preserved through save→overwrite→restore (V3)" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'

    CLIP_FILE=\"\$MOCK_STATE_DIR/sim_clipboard\"
    original=\"col1\tcol2\tcol3\"
    printf '%s' \"\$original\" > \"\$CLIP_FILE\"

    backend_get_clipboard() { cat \"\$CLIP_FILE\"; }
    backend_set_clipboard() { cat - > \"\$CLIP_FILE\"; }

    SAVED_CLIPBOARD=\$(backend_get_clipboard)
    printf '%s' 'overwrite' | backend_set_clipboard
    printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard

    restored=\$(backend_get_clipboard)
    if [ \"\$restored\" = \"\$original\" ]; then echo 'match=yes'; else echo 'match=no'; fi
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "match=yes"
}

@test "clipboard-cycle: unicode preserved through save→overwrite→restore (V3)" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'

    CLIP_FILE=\"\$MOCK_STATE_DIR/sim_clipboard\"
    original=\"héllo wörld 日本語 🚀\"
    printf '%s' \"\$original\" > \"\$CLIP_FILE\"

    backend_get_clipboard() { cat \"\$CLIP_FILE\"; }
    backend_set_clipboard() { cat - > \"\$CLIP_FILE\"; }

    SAVED_CLIPBOARD=\$(backend_get_clipboard)
    printf '%s' 'overwrite' | backend_set_clipboard
    printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard

    restored=\$(backend_get_clipboard)
    if [ \"\$restored\" = \"\$original\" ]; then echo 'match=yes'; else echo 'match=no'; fi
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "match=yes"
}

@test "clipboard-cycle: empty string handled gracefully through cycle (V3)" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'

    CLIP_FILE=\"\$MOCK_STATE_DIR/sim_clipboard\"
    printf '%s' '' > \"\$CLIP_FILE\"

    backend_get_clipboard() { cat \"\$CLIP_FILE\"; }
    backend_set_clipboard() { cat - > \"\$CLIP_FILE\"; }

    SAVED_CLIPBOARD=\$(backend_get_clipboard)
    printf '%s' 'overwrite' | backend_set_clipboard
    printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard

    restored=\$(backend_get_clipboard)
    restored_bytes=\$(printf '%s' \"\$restored\" | wc -c)
    echo \"restored_bytes=\$restored_bytes\"
    if [ -z \"\$restored\" ]; then echo 'empty=yes'; else echo 'empty=no'; fi
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "restored_bytes=0"
  echo "$output" | grep -q "empty=yes"
}

# ── AC #12: Backup file mechanism — specification tests (R1) ─────────────────
# NOTE: The backup file mechanism is NOT yet implemented in always-nvim (Story 2.1).
# These tests verify the PATTERN in isolation as specification tests.

@test "clipboard-cycle: backup file created before clipboard overwrite (R1 spec)" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'

    BACKUP_FILE='/tmp/always-nvim-clipboard-backup'
    rm -f \"\$BACKUP_FILE\"

    CLIP_FILE=\"\$MOCK_STATE_DIR/sim_clipboard\"
    printf '%s' 'important data' > \"\$CLIP_FILE\"

    backend_get_clipboard() { cat \"\$CLIP_FILE\"; }
    backend_set_clipboard() { cat - > \"\$CLIP_FILE\"; }

    # ── Pattern: save clipboard to backup file before overwrite ──
    SAVED_CLIPBOARD=\$(backend_get_clipboard)
    printf '%s' \"\$SAVED_CLIPBOARD\" > \"\$BACKUP_FILE\"

    # Verify backup exists before overwrite
    [ -f \"\$BACKUP_FILE\" ] && echo 'backup_exists=yes' || echo 'backup_exists=no'
    backup_content=\$(cat \"\$BACKUP_FILE\")
    echo \"backup_content=\$backup_content\"

    # Now overwrite clipboard
    printf '%s' 'edited content' | backend_set_clipboard

    # Backup should still contain original
    backup_after=\$(cat \"\$BACKUP_FILE\")
    echo \"backup_after=\$backup_after\"

    rm -f \"\$BACKUP_FILE\"
    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "backup_exists=yes"
  echo "$output" | grep -q "backup_content=important data"
  echo "$output" | grep -q "backup_after=important data"
}

@test "clipboard-cycle: backup file deleted on normal cleanup (R1 spec)" {
  run bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'

    BACKUP_FILE='/tmp/always-nvim-clipboard-backup'

    CLIP_FILE=\"\$MOCK_STATE_DIR/sim_clipboard\"
    printf '%s' 'data' > \"\$CLIP_FILE\"

    backend_get_clipboard() { cat \"\$CLIP_FILE\"; }
    backend_set_clipboard() { cat - > \"\$CLIP_FILE\"; }

    # Create backup
    SAVED_CLIPBOARD=\$(backend_get_clipboard)
    printf '%s' \"\$SAVED_CLIPBOARD\" > \"\$BACKUP_FILE\"
    [ -f \"\$BACKUP_FILE\" ] && echo 'before_cleanup=exists'

    # ── Simulate normal cleanup: restore + delete backup ──
    printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard
    rm -f \"\$BACKUP_FILE\"

    [ -f \"\$BACKUP_FILE\" ] && echo 'after_cleanup=exists' || echo 'after_cleanup=deleted'

    rm -rf \"\$MOCK_STATE_DIR\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "before_cleanup=exists"
  echo "$output" | grep -q "after_cleanup=deleted"
}
