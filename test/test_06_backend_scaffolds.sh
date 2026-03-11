#!/bin/bash
# Tests for Story 1.1 Task 6: Backend scaffolds with contract headers (AC #1)
# Verifies both backend files have:
# - 6 stub functions (return 0 or placeholder)
# - Contract comment block
# - shellcheck directives

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0

fail() {
	echo "FAIL: $1" >&2
	FAILURES=$((FAILURES + 1))
}

BACKEND_FUNCTIONS=(
	"backend_get_selection"
	"backend_get_clipboard"
	"backend_set_clipboard"
	"backend_simulate_paste"
	"backend_get_active_window"
	"backend_refocus_window"
)

for backend_file in "backends/x11.sh" "backends/wayland.sh"; do
	full_path="$PROJECT_ROOT/$backend_file"

	# --- Task 6.3: Contract comment block ---
	grep -q "Backend Interface Contract" "$full_path" || fail "$backend_file missing contract comment block"
	grep -q "ADC-1" "$full_path" || fail "$backend_file missing ADC-1 reference"
	grep -q "ADC-2" "$full_path" || fail "$backend_file missing ADC-2 reference"

	# --- Task 6.4: shellcheck directives ---
	grep -q "# shellcheck shell=bash" "$full_path" || fail "$backend_file missing shellcheck shell=bash"
	grep -q "# shellcheck disable=SC2034" "$full_path" || fail "$backend_file missing shellcheck disable=SC2034"

	# --- Task 6.1/6.2: 6 stub functions ---
	for func in "${BACKEND_FUNCTIONS[@]}"; do
		grep -q "${func}()" "$full_path" || fail "$backend_file missing function: $func"
	done

	# --- Verify functions contain return 0 or placeholder ---
	func_count=$(grep -c '()' "$full_path" | tr -d ' ')
	[ "$func_count" -ge 6 ] || fail "$backend_file should have at least 6 function definitions, found $func_count"

	# --- Verify functions are sourceable without error ---
	output=$(bash -c "source '$full_path'" 2>&1)
	rc=$?
	[ $rc -eq 0 ] || fail "$backend_file has source errors: $output"

	# --- Verify each function returns 0 ---
	for func in "${BACKEND_FUNCTIONS[@]}"; do
		output=$(bash -c "source '$full_path'; $func" 2>&1)
		rc=$?
		[ $rc -eq 0 ] || fail "$backend_file: $func does not return 0 (rc=$rc)"
	done
done

exit $FAILURES
