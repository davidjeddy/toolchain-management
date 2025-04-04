#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage: /path/to/script/backup_delete_all_recovery_points.sh <BACKUP_VAULT_NAME> <REGION>
# example: /path/to/script/backup_delete_all_recovery_points.sh dev-toolbox-shared-kmsd eu-west-1
# versions
# 0.0.1 - Init

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
