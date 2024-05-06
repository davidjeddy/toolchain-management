#!/usr/bin/env bash

set -e

# usage ./libs/bash/install.sh (optional) branch_name
# example ./libs/bash/install.sh fix/ICON-39280/connect_preprod_module_revert_to_0_36_7_due_to_kms_permissions

# Version: 0.5.11 - 2024-05-06 - ADD Git feature checks - David J Eddy
# Version: 0.5.10 - 2024-04-22
# Version: 0.5.8  - 2024-03-19

## configuration

if [[ $WL_TF_DEPLOYMENT_LOG == "TRACE" ]]
then 
    set -x
fi

## vars

### Configure required ENV VAR

if [[ ! $WORKSPACE ]]
then
    declare WORKSPACE
    WORKSPACE="$(git rev-parse --show-toplevel)"
    export WORKSPACE
fi
printf "INFO: WORKSPACE %s\n" "${WORKSPACE}"

declare WL_GC_TOOLCHAIN_BRANCH
WL_GC_TOOLCHAIN_BRANCH="main"
if [[ "$1" != "" ]]
then
    WL_GC_TOOLCHAIN_BRANCH="${1}"
fi
export WL_GC_TOOLCHAIN_BRANCH
printf "INFO: Toolchain branch is %s\n" "$WL_GC_TOOLCHAIN_BRANCH"

## functions

## logic

# Comment this section to develop locally w/o wiping the toolchain downstream project on every run
printf "INFO: Removing existing .tmp if exists.\n"
rm -rf "$WORKSPACE/.tmp" || exit 1
printf "INFO: Clone toolchain-management project locally into %s/.tmp\n" "$(pwd)"
git clone --quiet git@gitlab.test.igdcs.com:cicd/terraform/tools/toolchain-management.git "$WORKSPACE/.tmp/toolchain-management"
# Even if main, checkout anyways
cd "$WORKSPACE/.tmp/toolchain-management"
git checkout "$WL_GC_TOOLCHAIN_BRANCH" --force
cd "$WORKSPACE" || exit 1

printf "INFO: Execute toolchain-management installer...\n"
"$WORKSPACE/.tmp/toolchain-management/libs/bash/install.sh" "$@"

printf "INFO: Installing Git pre-commit hooks.\n"
rm -rf "$WORKSPACE/.git/hooks/pre-commit" || true
ln -sfn "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/pre-commit.sh" "$WORKSPACE/.git/hooks/pre-commit"

printf "INFO: Installing Git pre-push hooks.\n"
rm -rf "$WORKSPACE/.git/hooks/pre-push" || true
ln -sfn "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/pre-push.sh" "$WORKSPACE/.git/hooks/pre-push"

# Git features
if [[ -f .gitattributes ]]
then
    printf "INFO: Configure git LFS.\n"
    git lfs track "*.iso"
    git lfs track "*.zip"
    git lfs track "*.gz"
fi

if [[ -f .gitsubmodules ]]
then
    printf "INFO: Sync Git submodules.\n"
    git submodule update --init --recursive
fi

# Post-flight resets
cd "$WORKSPACE" || exit 1

printf "INFO: Done. Please reload your shell by running the following command: \"source ~/.bashrc\".\n"
