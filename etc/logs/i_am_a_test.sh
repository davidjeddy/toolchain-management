#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

printf "INFO: Starting...\n"

printf "INFO: Try for version 0.54.26\n"

printf "INFO: ...done.\n"
