#!/bin/bash
# Files utility functions for shell toolbox

in_path() {
  # Given a command and the PATH, tries to find the command. Returns 0 if
  #   found and executable; 1 if not. Note that this temporarily modifies
  #   the IFS (internal field separator) but restores it upon completion.
  local cmd=$1
  local ourpath=$2
  local result=1
  local old_ifs=$IFS
  IFS=":"

  for directory in $ourpath; do
    [ -x "$directory/$cmd" ] && result=0 # If we're here, we found the command.
  done

  IFS=$old_ifs
  return $result
}

check_for_cmd_in_path() {
  # Checks if a command exists in PATH or is an executable file.
  # Args: $1=command
  # Returns: 0 if found/executable, 1 if not executable, 2 if not in PATH
  local cmd=$1

  [ -n "$cmd" ] && {
    if [ "${cmd:0:1}" = "/" ]; then
      [ ! -x "$cmd" ] && return 1
    elif ! in_path "$cmd" "$PATH"; then
      return 2
    fi
  }
}
