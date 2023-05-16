#!/bin/bash -e

## configuration

if [[ $WL_TF_DEPLOYMENT_LOG == "TRACE" ]]
then 
    set -x
fi

## vars

declare ORIG_PWD
ORIG_PWD="$(pwd)"
export ORIG_PWD
printf "INFO: ORIG_PWD value is \n%s\n" "$ORIG_PWD"

declare PROJECT_ROOT
PROJECT_ROOT=$(git rev-parse --show-toplevel)
export PROJECT_ROOT
printf "INFO: PROJECT_ROOT value is \n%s\n" "$PROJECT_ROOT"

# get a list of changed files when using only the git staged list against previouse commit
declare TF_FILES_CHANGED
TF_FILES_CHANGED=$(git diff main --name-only | grep tf\$ | grep -v examples/ | grep -v .tmp/ | grep -v libs/kics || true)
export TF_FILES_CHANGED
printf "INFO: TF_FILES_CHANGED value is \n%s\n" "$TF_FILES_CHANGED"

if  [[ $TF_FILES_CHANGED == "" ]]
then
    printf "INFO: TF_FILES_CHANGED is empty; no Terraform changes detected, exiting.\n"
    exit 0
fi

declare MODULES_DIR
if [[ $TF_FILES_CHANGED != "" ]]
then
    MODULES_DIR=$(echo "$TF_FILES_CHANGED" | xargs -L1 dirname | uniq)
    export MODULES_DIR
    printf "INFO: MODULES_DIR value is \n%s\n" "$MODULES_DIR"
fi

## functions

# shellcheck disable=1091
. "${PROJECT_ROOT}/libs/bash/pre_commit_functions.sh"

## logic

for DIR in $MODULES_DIR
do
    printf "INFO: Reset to project home directory.\n"
    cd "${PROJECT_ROOT}" || exit

    printf "INFO: Changing into %s dir if it still exists.\n" "${DIR}"
    cd "$DIR" || continue

    # If a lock file exists, the module was init'd atleast once. Thus we want do it again if the .terraform dir is missing
    if [[ -f ".terraform.lock.hcl" && ! -d ".terraform" ]]
    then
        printf "INFO: Detected this module has not be initilized, doing it for you now.\n"
        terraform init -no-color -upgrade
        terraform providers lock -platform=linux_amd64 # ensure providers for Jenkins worker node
    fi

    # Do not allow in-project shared modules
    doNotAllowSharedModulesInsideDeploymentProjects

    # best practices and security scanning
    terraformCompliance

    # linting and syntax formatting
    terraformLinting

    # generate docs and meta-data only if checks do not fail
    documentation

    # supply chain attastation
    generateSBOM
done

## wrap up

cd "$ORIG_PWD" || exit

printf "INFO: Git pre-commit hook completed.\n"
