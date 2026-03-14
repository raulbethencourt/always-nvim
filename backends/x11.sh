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
#   backend_get_selection()    - Return currently selected text (primary selection)
#   backend_get_clipboard()    - Return current clipboard contents
#   backend_set_clipboard()    - Set clipboard from stdin
#   backend_simulate_paste()   - Simulate Ctrl+V keystroke
#   backend_get_active_window() - Return focused window identifier (opaque handle)
#   backend_refocus_window()   - Refocus a previously saved window

backend_get_selection() {
  # xclip returns 1 if selection is empty, but we want exit 0 + empty stdout
  xclip -o -selection primary 2>/dev/null || true
}

backend_get_clipboard() {
  # xclip returns 1 if clipboard is empty, but we want exit 0 + empty stdout
  xclip -o -selection clipboard 2>/dev/null || true
}

backend_set_clipboard() {
  # Read from stdin, write to clipboard
  # V3: Caller uses printf '%s' to avoid trailing newlines
  xclip -selection clipboard -i
}

backend_simulate_paste() {
  xdotool key --clearmodifiers ctrl+v
}

backend_get_active_window() {
  xdotool getactivewindow
}

backend_refocus_window() {
  local window="$1"
  [ -n "$window" ] && xdotool windowactivate "$window"
}

backend_clear_primary() {
  # Clear primary selection to prevent stale data triggering Mode B (ADC-4)
  printf '' | xclip -selection primary -i
}
