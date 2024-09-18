#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

if [[ ! $AWS_PROFILE ]]
then
    printf "ERR: ENV VAR AWS_PROFILE must be set.\n"
    exit 1
fi

# Execution

# Check for AWS_REGION
if [[ ! $AWS_REGION ]]
then
    read -p "INPUT: Set AWS region: " AWS_REGION
fi

# Check for AWS_EC2_INSTANCE_ID
if [[ ! $AWS_EC2_INSTANCE_ID ]]
then
    printf "INFO: Listing running instances in region:\n"

    aws ec2 describe-instances --region $AWS_REGION --query 'Reservations[*].Instances[*].[InstanceId]' --filters Name=instance-state-name,Values=running --output text

    read -p "INPUT: Select EC2 instance: " AWS_EC2_INSTANCE_ID
fi

aws ssm start-session --region $AWS_REGION --target $AWS_EC2_INSTANCE_ID
