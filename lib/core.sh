#!/bin/bash
# Core utility functions for shell toolbox

# Error Handling
echo_error() {
  # Prints an error message to stderr
  # shellcheck disable=SC2154
  echo "${REDF}Error:${RESET} $1" >&2
}
error_exit() {
  # Prints an error message to stderr and exits with a specified code (default 1).
  echo_error "$1"
  exit "${2:-1}"
}

# Logging
## Logging Configuration
export __TOOLBOX_LOG_PREFIX="" # Prefix for log messages
export __TOOLBOX_LOG_OUTPUT="" # File path for log output (empty means stdout)
export __TOOLBOX_LOG_LEVEL=0   # Minimum log level to output (0-9, higher = more verbose)

## Logging Functions
toolbox_log() {
  # Logs messages at a specified level, outputting to file and/or stdout based on config.
  # Args: $1=level (int), $2+=message parts
  [[ "${__TOOLBOX_LOG_LEVEL}" =~ ^[0-9]+$ ]] || {
    builtin echo "TOOLBOX ERROR : __TOOLBOX_LOG_LEVEL should be an integer, found ${__TOOLBOX_LOG_LEVEL} instead"
    exit 2
  }

  [[ "$1" =~ ^[0-9]+$ ]] || {
    builtin echo "TOOLBOX ERROR : toolbox_log() first parameter has to be an integer, used $1 instead"
    exit 2
  }

  [ "$__TOOLBOX_LOG_LEVEL" -lt "$1" ] && return 1
  shift

  [ -n "$__TOOLBOX_LOG_OUTPUT" ] && {
    printf "[%s - %-20s] " "$(date)" "$__TOOLBOX_LOG_PREFIX"
    printf "%s " "$@"
    printf "\n"
  } >>"$__TOOLBOX_LOG_OUTPUT"

  builtin echo "$@"
  return 0
}

# Output Override
echo() {
  # Overrides the built-in echo command to add logging capabilities.
  # All echo calls are first sent to toolbox_log(), and if logging fails,
  # falls back to the built-in echo.
  toolbox_log "0" "$@" || builtin echo "$@"
}
