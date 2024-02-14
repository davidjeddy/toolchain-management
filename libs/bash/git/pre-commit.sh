#!/bin/bash -e

## configuration

if [[ $WL_TF_DEPLOYMENT_LOG == "TRACE" ]]
then 
    set -x
fi

# We must get the root of the project and load the common fn() before calling specific action related fn()
if [[ ! $WORKSPACE ]]
then
    declare WORKSPACE
    WORKSPACE=$(git rev-parse --show-toplevel)
    printf "INFO: WORKSPACE: %s\n" "${WORKSPACE}"
fi

# shellcheck disable=SC1091
source "${WORKSPACE}/.tmp/toolchain-management/libs/bash/git/common.sh"

git fetch --all

declare CHANGES
CHANGES=$(git status --porcelain | sed s/^...//)
if [[ $CHANGES ]]
then
    exec "${WORKSPACE}" "${CHANGES}"
fi

printf "INFO: Git pre-commit hook completed successfully.\n"
