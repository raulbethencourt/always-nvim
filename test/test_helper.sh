# test_helper.sh — Centralized mock backend functions (ADC-7)
# Source this file explicitly in test setup:
#   source "$PROJECT_ROOT/test/test_helper.sh"
#
# All 6 backend_* functions are mocked with configurable behavior.
# Override per-test by redefining the function or setting MOCK_* variables.

# ── Mock control variables (set these BEFORE calling mock functions) ─────────
MOCK_SELECTION="${MOCK_SELECTION:-}"
MOCK_CLIPBOARD="${MOCK_CLIPBOARD:-}"
MOCK_WINDOW_ID="${MOCK_WINDOW_ID:-12345}"

# ── Mock state directory (captures that survive subshells) ────────────────────
MOCK_STATE_DIR="${MOCK_STATE_DIR:-$(mktemp -d /tmp/always-nvim-mock-XXXXXX)}"

# ── Mock control variables (set these BEFORE calling mock functions) ─────────
MOCK_PASTE_CALLED=0
MOCK_REFOCUS_ARG=""
MOCK_CURSOR_TO_END_CALLED=0
MOCK_CLEAR_PRIMARY_CALLED=0

# ── Mock backend functions (ADC-1: 6-function interface) ─────────────────────

backend_get_selection() {
  printf '%s' "$MOCK_SELECTION"
}

backend_get_clipboard() {
  printf '%s' "$MOCK_CLIPBOARD"
}

backend_set_clipboard() {
  cat - >"$MOCK_STATE_DIR/clipboard_set"
}

backend_simulate_paste() {
  MOCK_PASTE_CALLED=1
  printf '1' >"$MOCK_STATE_DIR/paste_called"
}

backend_get_active_window() {
  [ -z "$MOCK_WINDOW_ID" ] && return 1
  printf '%s' "$MOCK_WINDOW_ID"
}

backend_refocus_window() {
  MOCK_REFOCUS_ARG="$1"
  printf '%s' "$1" >"$MOCK_STATE_DIR/refocus_arg"
}

backend_clear_primary() {
  MOCK_CLEAR_PRIMARY_CALLED=1
  printf '1' >"$MOCK_STATE_DIR/clear_primary_called"
}

backend_cursor_to_end() {
  MOCK_CURSOR_TO_END_CALLED=1
  printf '1' >"$MOCK_STATE_DIR/cursor_to_end_called"
}

# ── Helpers for reading captured mock state ──────────────────────────────────

mock_get_clipboard_set() {
  [ -f "$MOCK_STATE_DIR/clipboard_set" ] && cat "$MOCK_STATE_DIR/clipboard_set"
}

mock_paste_was_called() {
  [ -f "$MOCK_STATE_DIR/paste_called" ]
}

mock_get_refocus_arg() {
  [ -f "$MOCK_STATE_DIR/refocus_arg" ] && cat "$MOCK_STATE_DIR/refocus_arg"
}

mock_cursor_to_end_was_called() {
  [ -f "$MOCK_STATE_DIR/cursor_to_end_called" ]
}

mock_clear_primary_was_called() {
  [ -f "$MOCK_STATE_DIR/clear_primary_called" ]
}

mock_reset() {
  rm -rf "$MOCK_STATE_DIR"
  MOCK_STATE_DIR=$(mktemp -d /tmp/always-nvim-mock-XXXXXX)
  MOCK_SELECTION=""
  MOCK_CLIPBOARD=""
  MOCK_WINDOW_ID="12345"
  MOCK_PASTE_CALLED=0
  MOCK_REFOCUS_ARG=""
  MOCK_CURSOR_TO_END_CALLED=0
  MOCK_CLEAR_PRIMARY_CALLED=0
}
