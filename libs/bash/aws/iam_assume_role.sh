#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage: /path/to/script/iam_assume_role.sh
# example: /path/to/script/iam_assume_role.sh $ROLE_NAME

## pre-flight checks

# Check if a role name is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <role-name>"
  echo "Example: $0 privileged"
  exit 1
fi

declare ROLE_NAME
ROLE_NAME=$1

# ensure the script is being sources, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  printf "ERR: Script must be invoked via source, not executed. Example: \"source /path/to/script/iam_assume_role.sh \${ROLE}\"\n"
  exit 1
fi

## Logic

# Get the AWS account ID dynamically
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
  echo "Error: Failed to retrieve AWS account ID."
  exit 1
fi

# Construct the role ARN
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/developer/${ROLE_NAME}"
ROLE_SESSION_NAME="Session-${ROLE_NAME//\//-}" # Replace '/' with '-' in session name

# Assume the role and capture the output
echo "Assuming role: $ROLE_ARN..."
ASSUME_ROLE_OUTPUT=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$ROLE_SESSION_NAME" \
  --output json)

if [ $? -ne 0 ]; then
  printf "Error: Failed to assume role. Please ensure the role name is correct and you have permissions.\n"
  exit 1
fi

# Extract credentials
AWS_ACCESS_KEY_ID=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.SessionToken')

# Export credentials
printf "export AWS_ACCESS_KEY_ID=%s\n" "$AWS_ACCESS_KEY_ID"
printf "export AWS_SECRET_ACCESS_KEY=%s\n" "$AWS_SECRET_ACCESS_KEY"
printf "export AWS_SESSION_TOKEN=%s\n" "$AWS_SESSION_TOKEN"

printf "Successfully assumed role '%s' and exported credentials:\n" "$ROLE_NAME"
printf "AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN are now available.\n"
printf "You can use the AWS CLI with the assumed role.\n"
printf "Done\n"
