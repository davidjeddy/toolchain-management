#!/bin/bash

# Recommended
# - add an alias for reference to this : alias boa="~/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management/libs/bash/bambora_onelogin_aws.sh"
# Usage
# bambora_onelogin_aws.sh ${ACCOUNT} ${MFA_TOKEN}
# Example
# bambora_onelogin_aws.sh worldline-gc-connect-staging 844141
# Version
# 0.0.1

if [[ ! $1 || ! $2 ]]
then
  echo "FATAL: Expecting two arguments, exiting."
  exit 1
fi

echo "INFO: Starting Bambora OneLogin authentication process..."

declare AWS_PROFILE
declare PROFILE
declare TOKEN
declare TMP

PROFILE="$1"
TOKEN="$2"
TMP=$(yes "$TOKEN" | onelogin-aws-login -C "$PROFILE")

# There appears to be only 1 success case and multiple failure scenarios so only checking for success
if [[ ! "$TMP" =~ "Credentials cached" ]] 
then
  echo "$TMP"
  exit 1
fi

# parse response
AWS_PROFILE=${TMP##* }
echo "INFO: AWS_PROFILE: $AWS_PROFILE"

echo "copy/paste/execute the following line:
export AWS_PROFILE=$AWS_PROFILE"

echo "INFO: done."