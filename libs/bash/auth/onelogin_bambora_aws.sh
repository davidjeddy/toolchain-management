#!/bin/bash -l

# set -exo pipefail # For debuggin
set -eo pipefail

# shellcheck disable=SC1090
source $HOME/.bashrc

# Example: source /path/to/script/bambora_onelogin_aws.sh worldline-gc-connect-staging
# Recommended: Add the script invokation to .basrc with an alias for each account: alias oli_bmbr_cicd_build_dev="source /path/to/script/onelogin_bambora_aws.sh worldline-gc-cicd-build-dev"
# Version:
# 0.0.1 - init
# 0.1.0 - libs/bash/auth/onelogin_bambora_aws.sh now masks MFA token
#       - libs/bash/auth/onelogin_bambora_aws.sh now exports AWS_PROFILE if invoked using `source` as is documented in the script
# 0.1.1 - Fix output formatting when asking for MFA token 
# Usage: source /path/to/script/bambora_onelogin_aws.sh ${ACCOUNT}

if [[ ! $1 ]]
then
  printf "FATAL: Expecting argument one to be account name from ~/.onelogin-aws.config. Exiting.\n"
  exit 1
fi

printf "INFO: Starting Bambora OneLogin authentication process...\n"

declare AWS_PROFILE
declare PROFILE
declare RESPONSE
declare TOKEN

PROFILE="$1"

printf "MFA value: "
read -rs TOKEN
printf "\n"

printf "INFO: Sending authentication request...\n"

RESPONSE=$(yes "$TOKEN" | onelogin-aws-login -C "$PROFILE")

# There appears to be only 1 success case and multiple failure scenarios so only checking for success
if [[ ! "$RESPONSE" =~ "Credentials cached" ]] 
then
  printf "Non-success error message returned:\n%s\n" "$RESPONSE"
  exit 0
fi

# parse response
AWS_PROFILE=${RESPONSE##* }
printf "INFO: Exporting AWS_PROFILE %s\n" "$AWS_PROFILE"

export AWS_PROFILE

printf "INFO: ...done.\n"
