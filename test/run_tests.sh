#!/bin/bash
# Test runner for always-nvim using BATS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ensure BATS is available
if [ ! -x "$PROJECT_ROOT/test/bats/bin/bats" ]; then
	echo "Error: BATS not found at test/bats/bin/bats"
	exit 1
fi

echo "🧪 Running BATS tests..."
"$PROJECT_ROOT/test/bats/bin/bats" "$PROJECT_ROOT/test"/*.bats
