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

declare WORKSPACE
WORKSPACE=$(git rev-parse --show-toplevel)
export WORKSPACE
printf "WORKSPACE: %s\n" "${WORKSPACE}"

if [[ ! -d "$WORKSPACE/.tmp/toolchain-management/libs/kics/assets" ]]
then
    printf "ERR: IAC tool KICS query library missing from .tmp/toolchain-management/libs. Please re-run ./libs/bash/install.sh and retry your commit."
    exit 1
fi

# get a list of changed files when using only the git staged list against previouse commit
git fetch --all
declare TF_FILES_CHANGED
TF_FILES_CHANGED=$(git diff origin/main --name-only | grep tf\$ | \
    grep -v .tmp/ | \
    grep -v docs/ | \
    grep -v examples/ | \
    grep -v libs/ | \
    grep -v README.md | \
    grep -v sbom.xml | \
    grep -v terraform.tf \
    || true \
)
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
    MODULES_DIR=$(echo "$TF_FILES_CHANGED" | xargs -L1 dirname | sort | uniq)
    export MODULES_DIR
    printf "INFO: MODULES_DIR value is \n%s\n" "$MODULES_DIR"
fi

## functions

## logic


for DIR in $MODULES_DIR
do
    printf "INFO: Reset to project home directory.\n"
    cd "${WORKSPACE}" || exit 1

    printf "INFO: Changing into %s dir if it still exists.\n" "${DIR}"
    cd "$DIR" || continue

    # If a lock file exists, the module needs to be initilized.
    if [[ -f ".terraform.lock.hcl" ]]
    then
        terraform init -no-color
        terraform providers lock -platform=linux_amd64
    fi

    # shellcheck disable=1091
    source "${WORKSPACE}/.tmp/toolchain-management/libs/bash/git/pre_commit_functions.sh"

    # Create tmp dir to hold artifacts and reports
    createTmpDir

    # Do not allow in-project shared modules
    doNotAllowSharedModulesInsideDeploymentProjects

    # best practices and security scanning
    terraformCompliance

    # linting and syntax formatting
    terraformLinting

    # generate docs and meta-data only if checks do not fail
    documentation

    # supply chain attastation generation and diff comparison
    generateSBOM
done

## wrap up

cd "$ORIG_PWD" || exit

printf "INFO: Git pre-commit hook completed successfully.\n"
