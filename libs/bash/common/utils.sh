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
# Appends a single line code snippet to (script) file
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
  delete_line "[[ \":\$PATH:\" != *\":$path:\"* ]] && export PATH=\"$path:\$PATH\"" "$file"
  append_if "if [[ \":\$PATH:\" != *\":$path:\"* ]]; then export PATH=\"$path:\$PATH\"; fi" "$file"
}

# Delete line from file
#
# $1 Line to be deleted
# $2 File to be stripped from the line
function delete_line() {
  local line="$1"
  local file="$2"
  # DO NOT exit 1 if grep or mv fails
  {
    if grep -qxF "$line" "$file"; then
      grep -vxF "$line" "$file" > "$file.$$"
      mv "$file.$$" "$file"
    fi
  } || {
    return 0
  }
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
