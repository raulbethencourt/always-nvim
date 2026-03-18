# always-nvim Makefile

PROJECT_ROOT := $(shell pwd)
BATS := $(PROJECT_ROOT)/test/bats/bin/bats
TEST_DIR := $(PROJECT_ROOT)/test
SHELL_FILES := always-nvim backends/x11.sh backends/wayland.sh install.sh

.PHONY: help test lint install clean test-verbose

##———————— 💡 always-nvim development targets: 💡 ——————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-25s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

##
##———————— Tests ✅ ——————--————————————————————————————————————————————————
test: ## Run all BATS tests
	@echo "🧪 Running BATS tests..."
	@$(BATS) $(TEST_DIR)/*.bats

test-verbose: ## Run tests with verbose output
	@echo "🧪 Running BATS tests verbosilly..."
	@$(BATS) --verbose-run --print-output-on-failure $(TEST_DIR)/*.bats

lint: ## Run shellcheck on all shell files
	@echo "🔍 Running shellcheck..."
	@shellcheck $(SHELL_FILES) $(TEST_DIR)/*.sh

##
##———————— Tools 🧙 ————————------—————————————————————————————————————————-
install: ## Install the application 🚀 
	@./install.sh
	
clean: ## Remove lock files, backups, and temp artifacts
	@echo "🧹 Cleaning artifacts..."
	@rm -f /tmp/always-nvim-*.lock /tmp/always-nvim-*.backup
	@rm -f $(PROJECT_ROOT)/tmp.*.* 2>/dev/null || true
	@echo "  Done."
	
##
