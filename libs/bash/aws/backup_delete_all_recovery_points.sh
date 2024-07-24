#!/bin/bash -l

# set -exo pipefail # when debuggin
set -eo pipefail

# Enforce the session load like an interactive user
# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $WL_IAC_LOGGING == "TRACE" ]]
then 
    set -x
fi

# usage: /path/to/script/backup_delete_all_recovery_points.sh <BACKUP_VAULT_NAME> <REGION>
# example: /path/to/script/backup_delete_all_recovery_points.sh dev-toolbox-shared-kmsd eu-west-1
# versions
# 0.0.1 - Init

## Preflight

if [[ ! $AWS_PROFILE ]]
then
  printf "ERR: Please authenticate via OneLogin CLI before attempting to connect.\n"
  exit 1
fi

if [[ ! $1 || ! $2 ]]
then
    printf "ERR: Two arguments are required. See usage examples, exiting with error.\n"
    exit 1
fi

aws backup list-recovery-points-by-backup-vault \
    --backup-vault-name "$1" \
    --output json \
    --query 'RecoveryPoints[].[RecoveryPointArn]' \
    --region "$2" \
    | jq -r '.[] | "--recovery-point-arn '\\\"'" + .[0] + "'\\\"'" + .[1]' \
    |  xargs -L1 \
        aws backup delete-recovery-point \
            --backup-vault-name "$1" \
            --region "$2"
