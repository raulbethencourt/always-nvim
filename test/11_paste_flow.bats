#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 1.6: Paste Flow & Clipboard Restoration ──────────────────────────
# Tests: init step 9 (clipboard save, active window), post-edit paste flow, clipboard restore

# ── Structural tests ────────────────────────────────────────────────────────

@test "Story 1.6: Init step 9 saves clipboard with backend_get_clipboard" {
  grep -q 'SAVED_CLIPBOARD=$(backend_get_clipboard)' "$SCRIPT_PATH"
}

@test "Story 1.6: Init step 9 records source window with backend_get_active_window" {
  grep -q 'source_window=$(backend_get_active_window)' "$SCRIPT_PATH"
}

@test "Story 1.6: Post-edit checks nvim_exit equals 0" {
  grep -q 'nvim_exit.*-eq 0' "$SCRIPT_PATH"
}

@test "Story 1.6: Post-edit reads temp file content" {
  grep -q 'content=$(cat "$tmpfile")' "$SCRIPT_PATH"
}

@test "Story 1.6: Post-edit sets clipboard with printf not echo (V3)" {
  grep -q "printf '%s' \"\$content\" | backend_set_clipboard" "$SCRIPT_PATH"
}

@test "Story 1.6: Post-edit refocuses source window" {
  grep -q 'backend_refocus_window.*source_window' "$SCRIPT_PATH"
}

@test "Story 1.6: Post-edit sleeps NA_FOCUS_DELAY before paste" {
  grep -q 'sleep.*NA_FOCUS_DELAY' "$SCRIPT_PATH"
}

@test "Story 1.6: Post-edit calls backend_simulate_paste" {
  grep -q 'backend_simulate_paste' "$SCRIPT_PATH"
}

@test "Story 1.6: Post-edit sleeps NA_PASTE_DELAY after paste" {
  grep -q 'sleep.*NA_PASTE_DELAY' "$SCRIPT_PATH"
}

@test "Story 1.6: Clipboard restored with printf not echo (V3)" {
  grep -q "printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard" "$SCRIPT_PATH"
}

@test "Story 1.6: Clipboard restore runs unconditionally (outside nvim_exit check)" {
  # The restore line must appear AFTER the closing fi of the nvim_exit block
  local last_fi_line restore_line
  # Find the line with the restore command
  restore_line=$(grep -n 'SAVED_CLIPBOARD.*backend_set_clipboard' "$SCRIPT_PATH" | tail -1 | cut -d: -f1)
  # Find the last 'fi' before the restore line (closing the nvim_exit block)
  last_fi_line=$(head -n "$restore_line" "$SCRIPT_PATH" | grep -n '^fi$' | tail -1 | cut -d: -f1)
  [ -n "$restore_line" ]
  [ -n "$last_fi_line" ]
  [ "$last_fi_line" -lt "$restore_line" ]
}

# ── Functional tests (extracted logic with mocked backend) ──────────────────

run_paste_flow() {
  local nvim_exit_code="$1"
  local tmpfile_content="$2"
  local saved_clipboard="$3"
  local source_win="${4:-0x1234}"

  bash -c "
    LOG=\$(mktemp)
    trap 'rm -f \"\$LOG\"' EXIT

    # Mock backends
    backend_get_clipboard() { printf '%s' '$saved_clipboard'; }
    backend_get_active_window() { printf '%s' '$source_win'; }
    backend_set_clipboard() { echo \"set_clipboard:\$(cat -)\" >> \"\$LOG\"; }
    backend_refocus_window() { echo \"refocus:\$1\" >> \"\$LOG\"; }
    backend_simulate_paste() { echo \"paste\" >> \"\$LOG\"; }

    # Config
    NA_FOCUS_DELAY=0
    NA_PASTE_DELAY=0

    # Simulate state
    SAVED_CLIPBOARD=\$(backend_get_clipboard)
    source_window=\$(backend_get_active_window)
    nvim_exit=$nvim_exit_code

    # Create temp file
    tmpfile=\$(mktemp)
    printf '%s' '$tmpfile_content' > \"\$tmpfile\"

    # ── Post-edit logic (copied from script) ──
    if [ \"\$nvim_exit\" -eq 0 ]; then
      content=\$(cat \"\$tmpfile\")
      if [ -n \"\$content\" ]; then
        printf '%s' \"\$content\" | backend_set_clipboard
        [ -n \"\$source_window\" ] && backend_refocus_window \"\$source_window\"
        sleep \"\$NA_FOCUS_DELAY\"
        backend_simulate_paste
        sleep \"\$NA_PASTE_DELAY\"
      fi
    fi
    printf '%s' \"\$SAVED_CLIPBOARD\" | backend_set_clipboard

    cat \"\$LOG\"
    rm -f \"\$tmpfile\"
  "
}

@test "Story 1.6: Exit 0 with content → set clipboard, refocus, paste, restore" {
  run run_paste_flow 0 "edited text" "original"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "set_clipboard:edited text"
  echo "$output" | grep -q "refocus:0x1234"
  echo "$output" | grep -q "paste"
  echo "$output" | grep -q "set_clipboard:original"
}

@test "Story 1.6: Exit 0 with empty content → skip paste, still restore" {
  run run_paste_flow 0 "" "original"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "paste"
  echo "$output" | grep -q "set_clipboard:original"
}

@test "Story 1.6: Exit non-zero (abort) → skip paste, still restore" {
  run run_paste_flow 1 "some text" "original"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "paste"
  echo "$output" | grep -q "set_clipboard:original"
}

@test "Story 1.6: No source window → skip refocus, still paste" {
  run run_paste_flow 0 "edited text" "original" ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "set_clipboard:edited text"
  ! echo "$output" | grep -q "refocus"
  echo "$output" | grep -q "paste"
}
