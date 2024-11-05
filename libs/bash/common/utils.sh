#!/bin/false

# Conditional append of a line to a file
#
# Prevents appending the same line multiple times
#
# $1 Line to be appended to the file
# $2 Target file to be modified
function append_if() {
  local line="$1"
  local file="$2"
  if ! grep -qxF "$line" "$file"; then
    echo "$line" >> "$file"
  fi
}

# Conditional append of a PATH add to a file
#
# Appends a single line code snipppet to (script) file
# where a given path is conditionally added (prepended)
# to the PATH variable
#
# Line will not be appended if it can be already found in
# the file
#
# $1 Path to be added to the PATH variable
# $2 Script file where the code snippet is appended to
function append_add_path() {
  local path="$1"
  local file="$2"
  append_if "[[ \":\$PATH:\" != *\":$path:\"* ]] && export PATH=\"$path:\$PATH\"" "$file"
}

# Conditional add to the PATH
#
# Given path will be prepended to the PATH variable
# if not added to it yet
#
# $1 Path to be added to the PATH variable
function add_path() {
  local path="$1"
  if [[ ":$PATH:" != *":$path:"* ]]; then
    export PATH="$path:$PATH"
  fi
}
