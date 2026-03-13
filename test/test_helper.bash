# test_helper.bash
# Helper file for BATS tests

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
export PROJECT_ROOT
SCRIPT_PATH="$PROJECT_ROOT/always-nvim"
export SCRIPT_PATH

# Helper to check if a command exists in PATH (without failing the test if not found immediately)
check_cmd() {
	command -v "$1" >/dev/null 2>&1
}

setup() {
	# Set default environment variables for tests
	export PATH="$PROJECT_ROOT:$PATH"
}
