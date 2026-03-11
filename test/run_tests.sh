#!/bin/bash
# Minimal test runner for always-nvim
# Usage: bash test/run_tests.sh [test_file...]
# If no args, runs all test/test_*.sh files

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
ERRORS=""

run_test_file() {
	local test_file="$1"
	local test_name
	test_name="$(basename "$test_file")"
	local output
	output=$(bash "$test_file" 2>&1)
	local rc=$?
	if [ $rc -eq 0 ]; then
		echo "  ✅ $test_name"
		PASS=$((PASS + 1))
	else
		echo "  ❌ $test_name"
		ERRORS="${ERRORS}\n--- $test_name ---\n${output}\n"
		FAIL=$((FAIL + 1))
	fi
}

echo "🧪 Running tests..."
echo ""

if [ $# -gt 0 ]; then
	for f in "$@"; do
		run_test_file "$f"
	done
else
	for f in "$SCRIPT_DIR"/test_*.sh; do
		[ -f "$f" ] && [ "$(basename "$f")" != "test_helper.sh" ] && run_test_file "$f"
	done
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -gt 0 ]; then
	echo ""
	echo "Failures:"
	printf '%b' "$ERRORS"
	exit 1
fi

exit 0
