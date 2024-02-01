#!/bin/bash -e

## configuration

if [[ $WL_TF_DEPLOYMENT_LOG == "TRACE" ]]
then 
    set -x
fi

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
CHANGES=$(git diff origin/main --name-only)
if [[ $CHANGES ]]
then
    exec "${WORKSPACE}" "${CHANGES}"
fi

printf "INFO: Git pre-push hook completed successfully.\n"
