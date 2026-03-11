# shellcheck shell=bash
# shellcheck disable=SC2034

# Backend Interface Contract (ADC-1, ADC-2)
# ==========================================
# Each function follows the error contract:
#   Success: return data on stdout, exit code 0
#   Failure: exit code 1, stderr for diagnostics
#   Empty result: empty stdout, exit code 0
#
# Functions:
#   backend_get_selection()    - Return currently selected text (primary selection)
#   backend_get_clipboard()    - Return current clipboard contents
#   backend_set_clipboard()    - Set clipboard from stdin
#   backend_simulate_paste()   - Simulate Ctrl+V keystroke
#   backend_get_active_window() - Return focused window identifier (opaque handle)
#   backend_refocus_window()   - Refocus a previously saved window

backend_get_selection() {
	return 0
}

backend_get_clipboard() {
	return 0
}

backend_set_clipboard() {
	return 0
}

backend_simulate_paste() {
	return 0
}

backend_get_active_window() {
	return 0
}

backend_refocus_window() {
	return 0
}
