#!/bin/bash
# Tests for Story 1.1 Task 2: Init steps 1-2 (SCRIPT_DIR + library sourcing)
# Verifies AC #2 (Sources .toolbox from local lib directory)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0

fail() {
  echo "FAIL: $1" >&2
  FAILURES=$((FAILURES + 1))
}

# --- Test: SCRIPT_DIR resolution is in the script ---
grep -q 'SCRIPT_DIR=' "$PROJECT_ROOT/always-nvim" || fail "SCRIPT_DIR resolution missing"
grep -q 'cd "$(dirname "$0")"' "$PROJECT_ROOT/always-nvim" || fail "SCRIPT_DIR not using symlink-safe resolution"

# --- Test: Sources .toolbox from local lib directory ---
# Adjusted expectation: Logic uses $SCRIPT_DIR/lib/.toolbox instead of SHELLTOOLSPATH
grep -q 'source "$SCRIPT_DIR/lib/.toolbox"' "$PROJECT_ROOT/always-nvim" || fail "Missing local .toolbox sourcing"

# --- Test: Does NOT rely on SHELLTOOLSPATH ---
if grep -q 'SHELLTOOLSPATH' "$PROJECT_ROOT/always-nvim"; then
  fail "Script should not rely on SHELLTOOLSPATH anymore"
fi

exit $FAILURES
