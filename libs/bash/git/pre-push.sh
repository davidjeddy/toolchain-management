#!/bin/bash -e

## configuration

if [[ $WL_TF_DEPLOYMENT_LOG == "TRACE" ]]
then 
    set -x
fi

# shellcheck disable=SC1091
source ".tmp/toolchain-management/libs/bash/git/common.sh"

exec "origin/main"

printf "INFO: Git pre-push hook completed successfully.\n"
