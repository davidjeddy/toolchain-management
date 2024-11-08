#!/bin/bash -l

# set -exo pipefail # when debuggin
set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## Logic

if [[ ! $WORKSPACE ]]
then
    declare WORKSPACE
    WORKSPACE=$(git rev-parse --show-toplevel)
    export WORKSPACE
    printf "INFO: WORKSPACE %s\n" "${WORKSPACE}"
fi

# shellcheck disable=SC1091
source "${WORKSPACE}/.tmp/toolchain-management/libs/bash/git/common.sh"

# Toolchain autoUpdate - Do not auto-update right before doing compliance scanning
# if [[ ! "${WL_GC_TOOLCHAIN_UPDATE_OVERRIDE}" ]]
# then
#     printf "INFO: Toolchain Management automatic updates skipped due to override flag being provided.\n"
# else
#     autoUpdate
# fi

# Logic

declare DIFF_LOGIC
DIFF_LOGIC="git diff HEAD~1 --name-only"
printf "INFO: DIFF_LOGIC %s\n" "${DIFF_LOGIC}"

declare DIFF_LIST
DIFF_LIST=$(generateDiffList "${DIFF_LOGIC}")
if [[ ! ${DIFF_LIST} ]]
then
    printf "WARN: IAC DIFF_LIST is empty, exiting without error.\n"
    exit 0
fi
printf "INFO: DIFF_LIST: %s\n" "${DIFF_LIST}"

exec ${DIFF_LIST}

printf "INFO: Iac Compliance and Security scanninig completed.\n"
