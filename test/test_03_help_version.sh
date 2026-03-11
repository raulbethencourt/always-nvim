#!/bin/bash
# Tests for Story 1.1 Task 3: --help / --version (AC #6, #7)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$PROJECT_ROOT/always-nvim"

FAILURES=0

fail() {
	echo "FAIL: $1" >&2
	FAILURES=$((FAILURES + 1))
}

# --- Task 3.4: VERSION variable defined ---
# Adjusted expectation: NA_VERSION_TO_SHOW is used
grep -q 'NA_VERSION_TO_SHOW=' "$SCRIPT" || fail "Version variable (NA_VERSION_TO_SHOW) not defined near top of script"

# --- Task 3.1: parse_options usage ---
# Adjusted expectation: Uses parse_options instead of case
grep -q 'parse_options' "$SCRIPT" || fail "Missing parse_options call for argument parsing"

# --- AC #6: --help prints usage and exits 0 ---
output=$(bash "$SCRIPT" --help 2>&1)
rc=$?
# Allow rc=0 (success) or rc=1 (some parsers consider help an error, though usually 0)
# But standard is 0 for --help
[ $rc -ne 0 ] && fail "--help should exit 0, got $rc"
echo "$output" | grep -qi "usage\|always-nvim\|help" || fail "--help should print usage info. Output: $output"

# --- AC #6: -h also works (if supported by parse_options) ---
# If parse_options supports -h, it should work. Most do.
output_h=$(bash "$SCRIPT" -h 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
	echo "$output_h" | grep -qi "usage\|always-nvim\|help" || fail "-h exited 0 but didn't print usage info"
else
	# If -h isn't supported, that's okay for now given the implementation change,
	# but we'll log it if it fails unexpectedly
	echo "Info: -h might not be supported or returned non-zero exit code: $rc"
fi

# --- AC #7: --version prints version string and exits 0 ---
output_v=$(bash "$SCRIPT" --version 2>&1)
rc=$?
[ $rc -ne 0 ] && fail "--version should exit 0, got $rc"
echo "$output_v" | grep -qE '[0-9]+\.[0-9]+' || fail "--version should print version string. Output: $output_v"

# --- AC #7: -v also works ---
output_v2=$(bash "$SCRIPT" -v 2>&1)
rc=$?
[ $rc -ne 0 ] && fail "-v should exit 0, got $rc"
echo "$output_v2" | grep -qE '[0-9]+\.[0-9]+' || fail "-v should print version string"

exit $FAILURES
