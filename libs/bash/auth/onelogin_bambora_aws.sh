#!/bin/bash -l

# set -exo pipefail # for debugging
set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# Example: source /path/to/script/bambora_onelogin_aws.sh worldline-gc-connect-staging
# Recommended: Add the script invocation to .bashrc with an alias for each account: alias oli_bmbr_cicd_build_dev="source /path/to/script/onelogin_bambora_aws.sh worldline-gc-cicd-build-dev"
# Version:
# 0.0.1 - init
# 0.1.0 - libs/bash/auth/onelogin_bambora_aws.sh now masks MFA token
#       - libs/bash/auth/onelogin_bambora_aws.sh now exports AWS_PROFILE if invoked using `source` as is documented in the script
# 0.1.1 - Fix output formatting when asking for MFA token 
# 0.2.0 - Fix script failing due to response from onelogin-aws-login
# Usage: source /path/to/script/bambora_onelogin_aws.sh ${ACCOUNT}

declare AWS_PROFILE
declare OLI_PROFILE
declare RESPONSE
declare TOKEN

if [[ ! $1 ]]
then
  printf "FATAL: Expecting argument one to be account name from %s. Exiting.\n" "$HOME/.onelogin-aws.config"
  exit 1
fi
OLI_PROFILE="$1"

# logic

printf "INFO: Starting Bambora OneLogin authentication process...\n"

printf "MFA value: "
read -rs TOKEN
printf "\n"

printf "INFO: Sending authentication request...\n"

{
  # Capture the enture output, since it is non-zero SHELL assumes failure, as it should
  RESPONSE=$(yes "$TOKEN" | onelogin-aws-login --config-name "$OLI_PROFILE")
} || {
  # But we capture this `failure` and parse the response text. If bit success, we fail WITHOUT killing the shell session (exit 0)
  # There appears to be only 1 success case and multiple failure scenarios so only checking for success
  if [[ "$RESPONSE" != *"Credentials cached"* ]]
  then
    printf "Non-success error message returned:\n%s\n" "$RESPONSE"
    exit 0
  fi
}

# parse response
AWS_PROFILE=${RESPONSE##* }
printf "INFO: Exporting AWS_PROFILE %s\n" "$AWS_PROFILE"

export AWS_PROFILE

printf "INFO: ...done.\n"
