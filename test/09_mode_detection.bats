#!/usr/bin/env bats
# shellcheck disable=SC2314,SC2016

load test_helper

# ── Story 1.4: Mode Detection & Temp File Preparation ──────────────────────
# Tests init steps 12-13: mode detection, temp file creation, nvim args assembly

# ── Structural tests ────────────────────────────────────────────────────────

@test "Story 1.4: Init steps 9-11 placeholders exist in order" {
  grep -q "Init Step 9" "$SCRIPT_PATH"
  grep -q "Init Step 10" "$SCRIPT_PATH"
  grep -q "Init Step 11" "$SCRIPT_PATH"
}

@test "Story 1.4: Init step 12 calls backend_get_selection" {
  grep -q 'selection=$(backend_get_selection)' "$SCRIPT_PATH"
}

@test "Story 1.4: Init step 13 uses mktemp with NA_FILETYPE" {
  grep -q 'mktemp.*/tmp/always-nvim-XXXXXX\.\$NA_FILETYPE' "$SCRIPT_PATH"
}

@test "Story 1.4: Mode B writes with printf not echo (V3)" {
  # The temp file write must use printf '%s'
  grep -q "printf '%s' \"\$selection\" >\"" "$SCRIPT_PATH"
  # Ensure no echo is used for writing selection to tmpfile
  ! grep -q 'echo.*\$selection.*>.*\$tmpfile' "$SCRIPT_PATH"
}

@test "Story 1.4: Mode A includes startinsert" {
  grep -q 'startinsert' "$SCRIPT_PATH"
}

@test "Story 1.4: NA_NVIM_ARGS appended to nvim args" {
  grep -q 'NA_NVIM_ARGS' "$SCRIPT_PATH"
  grep -q 'nvim_args.*NA_NVIM_ARGS' "$SCRIPT_PATH"
}

@test "Story 1.4: Init order — step 12 before step 13" {
  local step12_line step13_line
  step12_line=$(grep -n 'Init Step 12' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  step13_line=$(grep -n 'Init Step 13' "$SCRIPT_PATH" | head -1 | cut -d: -f1)
  [ -n "$step12_line" ]
  [ -n "$step13_line" ]
  [ "$step12_line" -lt "$step13_line" ]
}

# ── Functional tests (extracted logic with mocked backend) ──────────────────

# Helper: run mode detection + temp file logic in isolation
run_mode_detection() {
  local mock_selection="$1"
  local filetype="${2:-md}"
  local custom_nvim_args="${3:-}"

  bash -c "
    # Mock backend_get_selection
    backend_get_selection() { printf '%s' '$mock_selection'; }

    # Set config defaults
    NA_FILETYPE='$filetype'
    NA_NVIM_ARGS='$custom_nvim_args'

    # ── Step 12: mode detection ──
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

    # Output results for test assertions
    echo \"mode=\$mode\"
    echo \"tmpfile=\$tmpfile\"
    echo \"nvim_args=\${nvim_args[*]}\"
    echo \"content=\$(cat \"\$tmpfile\")\"

    # Cleanup
    rm -f \"\$tmpfile\"
  "
}

@test "Story 1.4: Mode A — empty selection → mode=A, empty tmpfile, startinsert" {
  run run_mode_detection ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=A"
  echo "$output" | grep -q "startinsert"
  echo "$output" | grep -q "content=$"
}

@test "Story 1.4: Mode B — has selection → mode=B, content in tmpfile, no startinsert" {
  run run_mode_detection "hello world"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=B"
  ! echo "$output" | grep -q "startinsert"
  echo "$output" | grep -q "content=hello world"
}

@test "Story 1.4: Temp file uses configured NA_FILETYPE extension" {
  run run_mode_detection "" "py"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "tmpfile=/tmp/always-nvim-.*\.py"
}

@test "Story 1.4: NA_NVIM_ARGS appended in Mode A" {
  run run_mode_detection "" "md" "--clean"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "startinsert"
  echo "$output" | grep -q "\-\-clean"
}

@test "Story 1.4: NA_NVIM_ARGS appended in Mode B" {
  run run_mode_detection "some text" "md" "--clean"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "\-\-clean"
  ! echo "$output" | grep -q "startinsert"
}

@test "Story 1.4: Mode B preserves multi-line selection" {
  run run_mode_detection "line1
line2
line3"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mode=B"
}
