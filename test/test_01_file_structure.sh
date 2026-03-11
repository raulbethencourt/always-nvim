#!/bin/bash
# Tests for Story 1.1 Task 1: Project file structure
# Verifies AC #1 - all required files and directories exist

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0

assert_file_exists() {
	local path="$1"
	local desc="$2"
	if [ ! -f "$PROJECT_ROOT/$path" ]; then
		echo "FAIL: File missing: $path ($desc)" >&2
		FAILURES=$((FAILURES + 1))
	fi
}

assert_dir_exists() {
	local path="$1"
	local desc="$2"
	if [ ! -d "$PROJECT_ROOT/$path" ]; then
		echo "FAIL: Directory missing: $path ($desc)" >&2
		FAILURES=$((FAILURES + 1))
	fi
}

assert_executable() {
	local path="$1"
	if [ ! -x "$PROJECT_ROOT/$path" ]; then
		echo "FAIL: Not executable: $path" >&2
		FAILURES=$((FAILURES + 1))
	fi
}

assert_contains() {
	local path="$1"
	local pattern="$2"
	local desc="$3"
	if ! grep -q "$pattern" "$PROJECT_ROOT/$path" 2>/dev/null; then
		echo "FAIL: $path missing pattern '$pattern' ($desc)" >&2
		FAILURES=$((FAILURES + 1))
	fi
}

# Task 1.1: Main script exists with shebang and shellcheck
assert_file_exists "always-nvim" "main script"
assert_executable "always-nvim"
assert_contains "always-nvim" "#!/bin/bash" "shebang"
assert_contains "always-nvim" "# shellcheck shell=bash" "shellcheck directive"

# Task 1.2: backends/ directory exists
assert_dir_exists "backends" "backends directory"

# Task 1.3: backends/x11.sh scaffold
assert_file_exists "backends/x11.sh" "x11 backend scaffold"
assert_contains "backends/x11.sh" "# shellcheck shell=bash" "x11 shellcheck"

# Task 1.4: backends/wayland.sh scaffold
assert_file_exists "backends/wayland.sh" "wayland backend scaffold"
assert_contains "backends/wayland.sh" "# shellcheck shell=bash" "wayland shellcheck"

# Task 1.5: config reference file
assert_file_exists "config" "config reference file"
assert_contains "config" "NA_TERMINAL_CMD" "config has NA_TERMINAL_CMD"
assert_contains "config" "NA_BACKEND" "config has NA_BACKEND"
assert_contains "config" "NA_CLEAR_PRIMARY" "config has NA_CLEAR_PRIMARY"
assert_contains "config" "NA_FILETYPE" "config has NA_FILETYPE"
assert_contains "config" "NA_NVIM_ARGS" "config has NA_NVIM_ARGS"
assert_contains "config" "NA_PASTE_DELAY" "config has NA_PASTE_DELAY"
assert_contains "config" "NA_FOCUS_DELAY" "config has NA_FOCUS_DELAY"

# Task 1.6: test/ directory exists
assert_dir_exists "test" "test directory"

# Task 1.7: test/test_helper.sh scaffold
assert_file_exists "test/test_helper.sh" "test helper scaffold"

exit $FAILURES
