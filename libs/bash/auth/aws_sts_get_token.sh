#!/bin/bash -l

# set -exo pipefail # For debuggin
set -eo pipefail

# shellcheck disable=SC1090
source $HOME/.bashrc

# Parameters:
#   - MFA_DEVICE_ARN    the ARN of your MFA device (optional - if not provided, the script will try to get this information from user's account)
#   - TOKEN_CODE        the token provided by the MFA device (optional - if not provided, the user will be asked for it)
# usage: source /path/to/script/getAWSSessionToken.sh
#        source /path/to/script/getAWSSessionToken.sh MFA_DEVICE_ARN
#        source /path/to/script/getAWSSessionToken.sh MFA_DEVICE_ARN TOKEN_CODE
# example: source /path/to/script/getAWSSessionToken.sh
# example: source /path/to/script/getAWSSessionToken.sh arn:aws:iam::433890542894:mfa/david.eddy
# example: source /path/to/script/getAWSSessionToken.sh arn:aws:iam::433890542894:mfa/david.eddy 123456
# todo: Add testing via https://bach.sh, https://shellspec.info/, https://github.com/kward/shunit2 or similar modern BASH testing framework

# Versions
# 0.4.0 - 2022-10-11 - Selin Eryilmaz || David Eddy
# 0.3.0 - 2022-10-05 - David Eddy
# 0.2.0 - 2022-09-28 - David Eddy
# 0.1.0 - Kevin Krab

# Arguments to local vars

MFA_DEVICE_ARN="$1"
TOKEN_CODE="$2"

# Pre-flight checks

# source https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
# shellcheck disable=SC2034
(return 0 2>/dev/null) && sourced=1 || sourced=0

if [[ "$sourced" == 0 ]]
then
    printf "ERR: Script must be sources to function properly. Please invoke prepended with 'source', e.g.: 'source /path/to/script YOUR_MFA_DEVICE_ARN'.\n"
    exit 1
fi

if [[ $MFA_DEVICE_ARN == "" ]]
then
    printf "INFO: MFA device not provided, getting the information from account\n"
    # shellcheck disable=SC2207
    LIST_MFA_DEVICE_ARN=($(aws iam list-mfa-devices --query 'MFADevices[*].SerialNumber' --output text))
    NUMBER_OF_ARNS="${#LIST_MFA_DEVICE_ARN[@]}"
    if ((NUMBER_OF_ARNS == 0)); then
      printf "ERR: Could not find MFA device for user %s\n" "$(aws iam get-user --query "User.UserName" --output text)"
      exit 0
    elif ((NUMBER_OF_ARNS == 1)); then
      MFA_DEVICE_ARN="${LIST_MFA_DEVICE_ARN[0]}"
    else
      printf "Select you MFA device:\n"
      select CHOICE in "${MFA_DEVICE_ARN[@]}"; do
        # shellcheck disable=SC2076
        if [[ " ${MFA_DEVICE_ARN[*]} " =~ " ${CHOICE} " ]]; then
          MFA_DEVICE_ARN=${CHOICE}
          break
        else
          printf "Invalid MFA device selected, try again.\n"
        fi
      done
    fi
    printf "INFO: Using MFA device: %s\n" "$MFA_DEVICE_ARN"
fi

# Request MFA token value

if [[ $TOKEN_CODE == "" ]]
then
    echo "Enter MFA token (input hidden):"
    read -rs TOKEN_CODE
fi

# execution logic

# execute sts request

STS_RESPONSE=$(aws sts get-session-token --serial-number "$MFA_DEVICE_ARN" --token-code "$TOKEN_CODE" || exit 1)

# parse and assign response data

AWS_ACCESS_KEY_ID="$(echo "$STS_RESPONSE" | jq -r .Credentials.AccessKeyId)"
AWS_SECRET_ACCESS_KEY="$(echo "$STS_RESPONSE" | jq -r .Credentials.SecretAccessKey)"
AWS_SESSION_TOKEN="$(echo "$STS_RESPONSE" | jq -r .Credentials.SessionToken)"
AWS_TOKEN_EXPIRATION="$(echo "$STS_RESPONSE" | jq -r .Credentials.Expiration)"

# exports to shell

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
export AWS_TOKEN_EXPIRATION

# outputs

if [[
    $AWS_ACCESS_KEY_ID != "" &&
    $AWS_SECRET_ACCESS_KEY != "" &&
    $AWS_SESSION_TOKEN != "" &&
    $AWS_TOKEN_EXPIRATION != ""
]]
then
    printf "INFO: Authorization successful. VARs exported to your ENV:'.\n"
    printf "INFO: AWS_ACCESS_KEY_ID: %s...\n" "${AWS_ACCESS_KEY_ID:0:3}"
    printf "INFO: AWS_SECRET_ACCESS_KEY: %s...\n" "${AWS_SECRET_ACCESS_KEY:0:3}"
    printf "INFO: AWS_SESSION_TOKEN: %s...\n" "${AWS_SESSION_TOKEN:0:3}"
    printf "INFO: AWS_TOKEN_EXPIRATION: %s\n" "${AWS_TOKEN_EXPIRATION}"

    printf "INFO: This shell is now ready to use API credentials via the AWS CLI.\n"
fi
