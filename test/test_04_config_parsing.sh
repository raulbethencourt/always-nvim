#!/bin/bash
# Tests for Story 1.1 Task 4: Config parsing (AC #4, #5)
# AC #4: No config file → defaults set
# AC #5: Config file exists → defaults set first, then config sourced to override
# AC #14, #15: NA_ prefix, defaults-before-source pattern

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$PROJECT_ROOT/always-nvim"

FAILURES=0

fail() {
	echo "FAIL: $1" >&2
	FAILURES=$((FAILURES + 1))
}

export SHELLTOOLSPATH="$PROJECT_ROOT"

# --- Task 4.1: Verify defaults are set FIRST (not using ${VAR:-default} anti-pattern) ---
# Check the script sets defaults with direct assignment, NOT parameter expansion defaults
if grep -q 'NA_TERMINAL_CMD="\${NA_TERMINAL_CMD:-' "$SCRIPT"; then
	fail "Uses anti-pattern \${NA_TERMINAL_CMD:-default} instead of setting defaults first"
fi
if grep -q 'NA_BACKEND="\${NA_BACKEND:-' "$SCRIPT"; then
	fail "Uses anti-pattern \${NA_BACKEND:-default} instead of setting defaults first"
fi

# Verify all NA_ defaults are assigned
grep -q 'NA_TERMINAL_CMD=' "$SCRIPT" || fail "NA_TERMINAL_CMD default not set"
grep -q 'NA_BACKEND=' "$SCRIPT" || fail "NA_BACKEND default not set"
grep -q 'NA_CLEAR_PRIMARY=' "$SCRIPT" || fail "NA_CLEAR_PRIMARY default not set"
grep -q 'NA_FILETYPE=' "$SCRIPT" || fail "NA_FILETYPE default not set"
grep -q 'NA_NVIM_ARGS=' "$SCRIPT" || fail "NA_NVIM_ARGS default not set"
grep -q 'NA_PASTE_DELAY=' "$SCRIPT" || fail "NA_PASTE_DELAY default not set"
grep -q 'NA_FOCUS_DELAY=' "$SCRIPT" || fail "NA_FOCUS_DELAY default not set"

# --- Task 4.2: Verify config sourcing is conditional on file existing ---
grep -q '\.config/always-nvim/config' "$SCRIPT" || fail "Config path ~/.config/always-nvim/config not referenced"

# --- AC #4: No config file → all defaults exist ---
# We test by extracting the default values from the script logic
# Source the script up to the config section in a subshell with HOME set to temp dir
TEMP_HOME=$(mktemp -d)
output=$(HOME="$TEMP_HOME" bash -c '
    export SHELLTOOLSPATH="'"$PROJECT_ROOT"'"
    source "$SHELLTOOLSPATH"/lib/.toolbox
    # Source just the defaults section by extracting it
    # We will test by running the full script and checking variable state
    # For now, we run the script and see if it gets past config parsing without error
    # The script will fail at later steps (backend detection) but that is expected
    WAYLAND_DISPLAY="" DISPLAY=":0" XDG_SESSION_TYPE="" \
    bash "'"$SCRIPT"'" 2>&1; echo "RC=$?"
' 2>&1)
# Script may fail at dependency check or backend step, but should NOT fail at config step
if echo "$output" | grep -qi "config.*error\|config.*not found\|NA_.*unset"; then
	fail "Config parsing fails when no config file exists. Output: $output"
fi
rm -rf "$TEMP_HOME"

# --- AC #5: Config file exists → values override defaults ---
TEMP_HOME2=$(mktemp -d)
mkdir -p "$TEMP_HOME2/.config/always-nvim"
cat >"$TEMP_HOME2/.config/always-nvim/config" <<'CONF'
NA_FILETYPE="txt"
NA_PASTE_DELAY="0.5"
CONF

# Verify the sourcing pattern: defaults then source
# The default line for NA_FILETYPE should appear before the source config line
default_line=$(grep -n 'NA_FILETYPE=' "$SCRIPT" | head -1 | cut -d: -f1)
source_config_line=$(grep -n 'source.*\.config/always-nvim/config' "$SCRIPT" | head -1 | cut -d: -f1)
if [ -n "$default_line" ] && [ -n "$source_config_line" ]; then
	if [ "$default_line" -ge "$source_config_line" ]; then
		fail "Defaults must be set BEFORE sourcing config (default=$default_line, source=$source_config_line)"
	fi
else
	fail "Could not determine default/source line order"
fi

rm -rf "$TEMP_HOME2"

exit $FAILURES
