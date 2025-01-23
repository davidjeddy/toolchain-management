#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage: /path/to/script/ec2_ssm_start_session.sh
#        /path/to/script/ec2_ssm_start_session.sh [[REGION]]
#        /path/to/script/ec2_ssm_start_session.sh [[REGION]] [[INSTANCE_ID]]

if [[ "$1" ]]
then
    AWS_REGION="$1"
elif [[ ! $AWS_REGION ]] # Check for AWS_REGION
then
    read -rp "INPUT: Set AWS region: " AWS_REGION
fi

if [[ "$2" ]]
then
    AWS_EC2_INSTANCE_ID="$2"
else # List EC2 instance IDs
    printf "INFO: Listing running instances in region:\n"
    aws ec2 describe-instances --region "$AWS_REGION" --query 'Reservations[*].Instances[*].[InstanceId]' --filters Name=instance-state-name,Values=running --output text
    read -rp "INPUT: Select EC2 instance: " AWS_EC2_INSTANCE_ID
fi

# Execution

aws ssm start-session --region "$AWS_REGION" --target "$AWS_EC2_INSTANCE_ID"
