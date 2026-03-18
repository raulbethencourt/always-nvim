#!/usr/bin/env bats

load test_helper

@test "Task 6: backends/x11.sh structure and functions" {
  local full_path="$PROJECT_ROOT/backends/x11.sh"

  # Contract block
  run grep -q "Backend Interface Contract" "$full_path"
  [ "$status" -eq 0 ]
  run grep -q "ADC-1" "$full_path"
  [ "$status" -eq 0 ]

  # Shellcheck
  run grep -q "# shellcheck shell=bash" "$full_path"
  [ "$status" -eq 0 ]

  # Functions exist
  local BACKEND_FUNCTIONS=(
    "backend_get_selection"
    "backend_get_clipboard"
    "backend_set_clipboard"
    "backend_simulate_paste"
    "backend_get_active_window"
    "backend_refocus_window"
    "backend_clear_primary"
    "backend_cursor_to_end"
  )
  for func in "${BACKEND_FUNCTIONS[@]}"; do
    run grep -q "${func}()" "$full_path"
    [ "$status" -eq 0 ]
  done

  # Sourceable
  run bash -c "source '$full_path'"
  [ "$status" -eq 0 ]
}

@test "Task 6: backends/wayland.sh structure and functions" {
  local full_path="$PROJECT_ROOT/backends/wayland.sh"

  # Contract block
  run grep -q "Backend Interface Contract" "$full_path"
  [ "$status" -eq 0 ]

  # Shellcheck
  run grep -q "# shellcheck shell=bash" "$full_path"
  [ "$status" -eq 0 ]

  # Functions exist
  local BACKEND_FUNCTIONS=(
    "backend_get_selection"
    "backend_get_clipboard"
    "backend_set_clipboard"
    "backend_simulate_paste"
    "backend_get_active_window"
    "backend_refocus_window"
    "backend_clear_primary"
    "backend_cursor_to_end"
  )
  for func in "${BACKEND_FUNCTIONS[@]}"; do
    run grep -q "${func}()" "$full_path"
    [ "$status" -eq 0 ]
  done

  # Sourceable
  run bash -c "source '$full_path'"
  [ "$status" -eq 0 ]
}
