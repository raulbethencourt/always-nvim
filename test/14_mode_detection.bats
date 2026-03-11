#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 1.7: Mode Detection Tests (using centralized mock helper) ─────────
# Tests: Mode A/B detection, temp file creation, nvim args assembly
# Uses test/test_helper.sh mock pattern (ADC-7) instead of inline mocks

# ── Helper: run mode detection logic with mock helper ────────────────────────

run_mode_detection_with_helper() {
  local mock_selection="$1"
  local filetype="${2:-md}"
  local custom_nvim_args="${3:-}"

  # Use the centralized mock helper in a subshell
  bash -c "
    source '$PROJECT_ROOT/test/test_helper.sh'
    MOCK_SELECTION='$mock_selection'

    # Config
    NA_FILETYPE='$filetype'
    NA_NVIM_ARGS='$custom_nvim_args'

    # ── Step 12: mode detection (from always-nvim) ──
    selection=\$(backend_get_selection)
    if [ -z \"\$selection\" ]; then
      mode='A'
    else
      mode='B'
    fi

    # ── Step 13: temp file + nvim args ──
    tmpfile=\$(mktemp \"/tmp/always-nvim-XXXXXX.\$NA_FILETYPE\")

    nvim_args=()
    if [ \"\$mode\" = 'A' ]; then
      nvim_args+=(-c 'startinsert')
    fi

    # shellcheck disable=SC2086
    [ -n \"\$NA_NVIM_ARGS\" ] && nvim_args+=(\$NA_NVIM_ARGS)

    if [ \"\$mode\" = 'B' ]; then
      printf '%s' \"\$selection\" >\"\$tmpfile\"
    fi

    # Output for assertions
    echo \"mode=\$mode\"
    echo \"tmpfile=\$tmpfile\"
    echo \"nvim_args=\${nvim_args[*]}\"
    echo \"content=\$(cat \"\$tmpfile\")\"
    echo \"filesize=\$(wc -c < \"\$tmpfile\")\"

    rm -f \"\$tmpfile\"
  "
}

# ── AC #6: Empty selection → Mode A (FR10) ──────────────────────────────────

@test "mode-detection: empty selection via mock helper → mode=A (FR10)" {
  run run_mode_detection_with_helper ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=A"
}

# ── AC #7: Non-empty selection → Mode B, content captured (FR11) ─────────────

@test "mode-detection: non-empty selection via mock helper → mode=B (FR11)" {
  run run_mode_detection_with_helper "selected text"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=B"
  echo "$output" | grep -q "content=selected text"
}

# ── AC #8: Mode A temp file — empty with NA_FILETYPE extension (FR12) ───────

@test "mode-detection: Mode A creates empty temp file with NA_FILETYPE extension (FR12)" {
  run run_mode_detection_with_helper "" "py"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=A"
  echo "$output" | grep -q "tmpfile=/tmp/always-nvim-.*\.py"
  # File size should be 0 (empty file in Mode A)
  echo "$output" | grep -q "filesize=0"
}

@test "mode-detection: Mode A default filetype is md (FR12)" {
  run run_mode_detection_with_helper ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "tmpfile=/tmp/always-nvim-.*\.md"
}

# ── AC #9: Mode B temp file — pre-filled with selection via printf (FR13) ───

@test "mode-detection: Mode B pre-fills temp file with selection content (FR13)" {
  run run_mode_detection_with_helper "hello world"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=B"
  echo "$output" | grep -q "content=hello world"
}

@test "mode-detection: Mode B preserves multiline content via printf (FR13, V3)" {
  run run_mode_detection_with_helper "line1
line2
line3"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=B"
  # Verify no trailing newline added — exact byte count
  # "line1\nline2\nline3" = 17 bytes
  echo "$output" | grep -q "filesize=17"
}

# ── Mode A: nvim_args includes startinsert ──────────────────────────────────

@test "mode-detection: Mode A includes -c startinsert in nvim_args" {
  run run_mode_detection_with_helper ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "nvim_args=.*startinsert"
}

# ── Mode B: nvim_args does NOT include startinsert ──────────────────────────

@test "mode-detection: Mode B does NOT include startinsert in nvim_args" {
  run run_mode_detection_with_helper "some text"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "startinsert"
}

# ── NA_NVIM_ARGS appended in both modes ─────────────────────────────────────

@test "mode-detection: NA_NVIM_ARGS appended in Mode A" {
  run run_mode_detection_with_helper "" "md" "--clean"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "nvim_args=.*startinsert"
  echo "$output" | grep -q "nvim_args=.*--clean"
}

@test "mode-detection: NA_NVIM_ARGS appended in Mode B" {
  run run_mode_detection_with_helper "text" "md" "--clean"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "startinsert"
  echo "$output" | grep -q "nvim_args=.*--clean"
}
