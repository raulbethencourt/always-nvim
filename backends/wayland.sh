# shellcheck shell=bash
# shellcheck disable=SC2034

# Backend Interface Contract (ADC-1, ADC-2)
# ==========================================
# Each function follows the error contract:
#   Success: return data on stdout, exit code 0
#   Failure: exit code 1, stderr for diagnostics
#   Empty result: empty stdout, exit code 0
#
# Functions:
#   backend_get_selection()     - Return currently selected text (primary selection)
#   backend_get_clipboard()     - Return current clipboard contents
#   backend_set_clipboard()     - Set clipboard from stdin
#   backend_simulate_paste()    - Simulate Ctrl+V keystroke
#   backend_get_active_window() - Return focused window identifier (opaque handle)
#   backend_refocus_window()    - Refocus a previously saved window

backend_get_selection() {
  # V1: wl-paste --primary exits 1 on empty selection — normalize to exit 0
  local result
  result=$(wl-paste --primary --no-newline 2>/dev/null) || true
  printf '%s' "$result"
}

backend_get_clipboard() {
  # V2: wl-paste exits 1 on empty clipboard — normalize to exit 0
  local result
  result=$(wl-paste --no-newline 2>/dev/null) || true
  printf '%s' "$result"
}

backend_set_clipboard() {
  # V3: Caller uses printf '%s' to avoid trailing newlines
  wl-copy
}

backend_simulate_paste() {
  wtype -M ctrl -k v -m ctrl
}

backend_get_active_window() {
  # V4: Check for null/zero address from hyprctl
  local json addr
  json=$(hyprctl activewindow -j 2>/dev/null) || return 1
  addr=$(printf '%s' "$json" | jq -r '.address // empty' 2>/dev/null) || return 1
  [ -z "$addr" ] || [ "$addr" = "null" ] || [ "$addr" = "0x0" ] && return 1
  printf '%s' "$addr"
}

backend_refocus_window() {
  local window="$1"
  [ -n "$window" ] && hyprctl dispatch focuswindow "address:$window" >/dev/null 2>&1
}

backend_clear_primary() {
  # Clear primary selection to prevent stale data triggering Mode B (ADC-4)
  printf '' | wl-copy --primary
}

backend_cursor_to_end() {
  # Right arrow moves cursor to end of selection (unselects)
  wtype -k Right
}
