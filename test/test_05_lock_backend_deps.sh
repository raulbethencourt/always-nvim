#!/bin/bash
# Tests for Story 1.1 Task 5: Init steps 5-8 (lock, backend detect, source backend, deps)
# AC #8: X11 session → sources backends/x11.sh
# AC #9: Wayland session → sources backends/wayland.sh
# AC #10: NA_BACKEND override takes precedence
# AC #11: Improved heuristic with fallback tiers
# AC #12: Init steps 1-8 in order

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$PROJECT_ROOT/always-nvim"

FAILURES=0

fail() {
	echo "FAIL: $1" >&2
	FAILURES=$((FAILURES + 1))
}

export SHELLTOOLSPATH="$PROJECT_ROOT"

# --- Task 5.1: Lock file placeholder ---
grep -q 'LOCK_FILE=' "$SCRIPT" || fail "LOCK_FILE variable not defined"
grep -q '/tmp/always-nvim.lock' "$SCRIPT" || fail "Lock file path not /tmp/always-nvim.lock"

# --- Task 5.2: Minimal trap ---
grep -q "trap.*rm.*LOCK_FILE.*EXIT" "$SCRIPT" || fail "Minimal EXIT trap not set for lock file"

# --- Task 5.3: Backend detection function ---
grep -q 'detect_backend' "$SCRIPT" || fail "detect_backend function not defined"

# Verify 3-tier heuristic structure
grep -q 'NA_BACKEND' "$SCRIPT" || fail "Backend detection missing NA_BACKEND config override check"
grep -q 'WAYLAND_DISPLAY' "$SCRIPT" || fail "Backend detection missing WAYLAND_DISPLAY check (tier 1)"
grep -q 'XDG_SESSION_TYPE' "$SCRIPT" || fail "Backend detection missing XDG_SESSION_TYPE check (tier 2)"
grep -q 'DISPLAY' "$SCRIPT" || fail "Backend detection missing DISPLAY check (tier 3)"

# --- Task 5.4: Source backend file ---
grep -q 'source.*backends/' "$SCRIPT" || fail "Backend file not sourced"

# --- Task 5.5: Dependency checking ---
grep -q 'check_for_cmd_in_path' "$SCRIPT" || fail "check_for_cmd_in_path not used for dependency checks"

# --- AC #8: WAYLAND_DISPLAY unset, DISPLAY set → x11 ---
# We test the detect_backend function in isolation
output=$(SHELLTOOLSPATH="$PROJECT_ROOT" bash -c '
    source "'"$PROJECT_ROOT"'"/lib/.toolbox
    NA_BACKEND="auto"
    WAYLAND_DISPLAY=""
    XDG_SESSION_TYPE=""
    DISPLAY=":0"
    source <(sed -n "/^detect_backend()/,/^}/p" "'"$SCRIPT"'")
    detect_backend
')
[ "$output" = "x11" ] || fail "AC #8: Expected 'x11' when WAYLAND_DISPLAY unset + DISPLAY=:0, got '$output'"

# --- AC #9: WAYLAND_DISPLAY set → wayland ---
output=$(SHELLTOOLSPATH="$PROJECT_ROOT" bash -c '
    source "'"$PROJECT_ROOT"'"/lib/.toolbox
    NA_BACKEND="auto"
    WAYLAND_DISPLAY="wayland-0"
    DISPLAY=":0"
    XDG_SESSION_TYPE=""
    source <(sed -n "/^detect_backend()/,/^}/p" "'"$SCRIPT"'")
    detect_backend
')
[ "$output" = "wayland" ] || fail "AC #9: Expected 'wayland' when WAYLAND_DISPLAY set, got '$output'"

# --- AC #10: NA_BACKEND override → uses config value ---
output=$(SHELLTOOLSPATH="$PROJECT_ROOT" bash -c '
    source "'"$PROJECT_ROOT"'"/lib/.toolbox
    NA_BACKEND="x11"
    WAYLAND_DISPLAY="wayland-0"
    DISPLAY=":0"
    XDG_SESSION_TYPE="wayland"
    source <(sed -n "/^detect_backend()/,/^}/p" "'"$SCRIPT"'")
    detect_backend
')
[ "$output" = "x11" ] || fail "AC #10: Expected 'x11' when NA_BACKEND=x11 override, got '$output'"

output=$(SHELLTOOLSPATH="$PROJECT_ROOT" bash -c '
    source "'"$PROJECT_ROOT"'"/lib/.toolbox
    NA_BACKEND="wayland"
    WAYLAND_DISPLAY=""
    DISPLAY=":0"
    XDG_SESSION_TYPE=""
    source <(sed -n "/^detect_backend()/,/^}/p" "'"$SCRIPT"'")
    detect_backend
')
[ "$output" = "wayland" ] || fail "AC #10: Expected 'wayland' when NA_BACKEND=wayland override, got '$output'"

# --- AC #11: XDG_SESSION_TYPE fallback ---
output=$(SHELLTOOLSPATH="$PROJECT_ROOT" bash -c '
    source "'"$PROJECT_ROOT"'"/lib/.toolbox
    NA_BACKEND="auto"
    WAYLAND_DISPLAY=""
    DISPLAY=""
    XDG_SESSION_TYPE="wayland"
    source <(sed -n "/^detect_backend()/,/^}/p" "'"$SCRIPT"'")
    detect_backend
')
[ "$output" = "wayland" ] || fail "AC #11: Expected 'wayland' when XDG_SESSION_TYPE=wayland, got '$output'"

# --- No display server → error_exit ---
output=$(SHELLTOOLSPATH="$PROJECT_ROOT" bash -c '
    source "'"$PROJECT_ROOT"'"/lib/.toolbox
    NA_BACKEND="auto"
    WAYLAND_DISPLAY=""
    DISPLAY=""
    XDG_SESSION_TYPE=""
    source <(sed -n "/^detect_backend()/,/^}/p" "'"$SCRIPT"'")
    detect_backend
' 2>&1)
rc=$?
[ $rc -ne 0 ] || fail "detect_backend should exit non-zero when no display server detected"

# --- AC #12: Init order - lock before backend before source ---
lock_line=$(grep -n 'LOCK_FILE=' "$SCRIPT" | head -1 | cut -d: -f1)
detect_line=$(grep -n 'detect_backend' "$SCRIPT" | grep -v '^[[:space:]]*#' | grep -v 'function\|detect_backend()' | head -1 | cut -d: -f1)
source_backend_line=$(grep -n 'source.*backends/' "$SCRIPT" | head -1 | cut -d: -f1)

if [ -n "$lock_line" ] && [ -n "$detect_line" ] && [ -n "$source_backend_line" ]; then
	if [ "$lock_line" -ge "$detect_line" ]; then
		fail "Lock (step 5) must come before backend detect (step 6): lock=$lock_line, detect=$detect_line"
	fi
	if [ "$detect_line" -ge "$source_backend_line" ]; then
		fail "Backend detect (step 6) must come before source backend (step 7): detect=$detect_line, source=$source_backend_line"
	fi
fi

exit $FAILURES
