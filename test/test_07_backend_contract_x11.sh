#!/bin/bash
# Test 07: Backend Contract Verification (X11)
# Verifies that backend functions call the correct external commands with correct arguments.

# Setup test environment
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
MOCK_DIR=$(mktemp -d)
LOG_FILE="$MOCK_DIR/mock_log"

# Clean up on exit
trap 'rm -rf "$MOCK_DIR"' EXIT

# Mock xclip
cat >"$MOCK_DIR/xclip" <<EOF
#!/bin/bash
echo "xclip \$*" >> "$LOG_FILE"
# Simulate specific behaviors based on args if needed
if [[ "\$*" == *"-o"* ]]; then
    # Output something for get
    if [[ "\$*" == *"primary"* ]]; then
        echo "mock_selection"
    elif [[ "\$*" == *"clipboard"* ]]; then
        echo "mock_clipboard"
    fi
else
    # Read stdin for set
    cat - > /dev/null
fi
EOF
chmod +x "$MOCK_DIR/xclip"

# Mock xdotool
cat >"$MOCK_DIR/xdotool" <<EOF
#!/bin/bash
echo "xdotool \$*" >> "$LOG_FILE"
if [[ "\$*" == *"getactivewindow"* ]]; then
    echo "12345"
fi
EOF
chmod +x "$MOCK_DIR/xdotool"

# Add mocks to PATH
export PATH="$MOCK_DIR:$PATH"

# Source the backend
source "$PROJECT_ROOT/backends/x11.sh"

# Test 1: backend_get_selection
echo "Testing backend_get_selection..."
output=$(backend_get_selection)
if [ "$output" != "mock_selection" ]; then
	echo "FAILED: backend_get_selection returned '$output', expected 'mock_selection'"
	exit 1
fi
if ! grep -q "xclip -o -selection primary" "$LOG_FILE"; then
	echo "FAILED: xclip not called correctly for get_selection"
	exit 1
fi
echo "PASS"

# Test 2: backend_get_clipboard
echo "Testing backend_get_clipboard..."
output=$(backend_get_clipboard)
if [ "$output" != "mock_clipboard" ]; then
	echo "FAILED: backend_get_clipboard returned '$output', expected 'mock_clipboard'"
	exit 1
fi
if ! grep -q "xclip -o -selection clipboard" "$LOG_FILE"; then
	echo "FAILED: xclip not called correctly for get_clipboard"
	exit 1
fi
echo "PASS"

# Test 3: backend_set_clipboard
echo "Testing backend_set_clipboard..."
echo "new_content" | backend_set_clipboard
if ! grep -q "xclip -selection clipboard -i" "$LOG_FILE"; then
	echo "FAILED: xclip not called correctly for set_clipboard"
	exit 1
fi
echo "PASS"

# Test 4: backend_simulate_paste
echo "Testing backend_simulate_paste..."
backend_simulate_paste
if ! grep -q "xdotool key --clearmodifiers ctrl+v" "$LOG_FILE"; then
	echo "FAILED: xdotool not called correctly for simulate_paste"
	exit 1
fi
echo "PASS"

# Test 5: backend_get_active_window
echo "Testing backend_get_active_window..."
window=$(backend_get_active_window)
if [ "$window" != "12345" ]; then
	echo "FAILED: backend_get_active_window returned '$window', expected '12345'"
	exit 1
fi
if ! grep -q "xdotool getactivewindow" "$LOG_FILE"; then
	echo "FAILED: xdotool not called correctly for get_active_window"
	exit 1
fi
echo "PASS"

# Test 6: backend_refocus_window
echo "Testing backend_refocus_window..."
backend_refocus_window "12345"
if ! grep -q "xdotool windowactivate 12345" "$LOG_FILE"; then
	echo "FAILED: xdotool not called correctly for refocus_window"
	exit 1
fi
echo "PASS"

exit 0
