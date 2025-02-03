#!/bin/bash

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage: /path/to/script/unset_env_var.sh
# example: /path/to/script/unset_env_var.sh

# function

# logic

printf "INFO: AWS ENV VAR before:\n"
printenv | grep AWS | sort

unset AWS_ACCESS_KEY_ID=
unset AWS_DEFAULT_REGION
unset AWS_REGION
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_SSO_ACCOUNT_ID
unset AWS_SSO
unset AWS_SSO_DEFAULT_REGION
unset AWS_SSO_PROFILE
unset AWS_SSO_ROLE_ARN=
unset AWS_SSO_ROLE_NAME
unset AWS_SSO_SESSION_EXPIRATION

printf "INFO: AWS ENV VAR after:\n"
printenv | grep AWS | sort

printf "INFO: Done.\n"
