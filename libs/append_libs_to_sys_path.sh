#!/bin/bash

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## documentation
## Optional helper to add path to ENV VAR PATH to enable easier access
## Recommended to clone a copy of TC to project path 

## preflight

### Do not use this in an instance where TC is a dependency. It must only be used from a stand alone clone of the project
if [[ $PWD == *.tmp* ]]
then
    printf "ERR: Invalid usage. See code source for debugging.\n"
    exit 1
fi

## functions

## logic

printf "INFO: Appending paths to ENV VAR PATH.\n"

append_add_path "$PWD/bash/auth/bash/auth" "$SESSION_SHELL"
append_add_path "$PWD/bash/aws" "$SESSION_SHELL"
append_add_path "$PWD/bash/common" "$SESSION_SHELL"
append_add_path "$PWD/bash/container" "$SESSION_SHELL"
append_add_path "$PWD/bash/git" "$SESSION_SHELL"
append_add_path "$PWD/bash/iac" "$SESSION_SHELL"

printf "INFO: Done.\n"
