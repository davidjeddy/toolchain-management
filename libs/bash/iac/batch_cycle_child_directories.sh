#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# Example /path/to/script/batch_iac_cycle_child_directories.sh
# Note Must be used from the parent directory containing the module library
# Sources
# https://stackoverflow.com/questions/2107945/how-to-loop-over-directories-in-linux
# Usage /path/to/script/batch_iac_cycle_child_directories.sh
# Versions
# 0.1.0 - 2024-08-=5 - David Eddy - Init add of logic

# input validations

# Configuration

declare TF_APPLY
declare ENDTIME
declare OWD
declare STARTTIME

TF_APPLY="false" # bool
STARTTIME=$(date +%s) # string
OWD=$(pwd) # string

if [[ "${1}" != "" ]]
then
    TF_APPLY="${1}"
fi

# Execution

{
    for DIR in $(pwd)
    do
        DIR=${DIR%*/} # remove the trailing "/"
        printf "INFO: Processing directory %s\n" "${DIR##*/}" # print everything after the final "/"

        printf "INFO: Changing into %s\n" "$DIR"
        cd "$DIR" || exit 1

        rm -rf .terra*
        terraform init
        terraform plan

        if [[ $TF_APPLY == "true" ]]
        then
            terraform apply --auto-approve
        fi

        cd ../
    done
} || {
    cd "${OWD}" || exit 1
}

ENDTIME=$(date +%s)
printf "INFO: Elapsed Time: %s seconds \n" "$((ENDTIME-STARTTIME))"
printf "INFO ...done.\n"
