#!/usr/bin/env bash

set -e

# See header of terraform-toolchain-management project./libs/bash/install.sh for advanced argument options

# usage install.sh (optional) branch_name
# example install.sh fix/ICON-39280/connect_preprod_module_revert_to_0_36_7_due_to_kms_permissions

# Version: 0.5.8 - 2014-03-19

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
fi
printf "INFO: WORKSPACE %s\n" "${WORKSPACE}"
export WORKSPACE

# pre-flight checks and resets

declare WL_GC_TOOLCHAIN_BRANCH
if [[ "$1" != "" ]]
then
    WL_GC_TOOLCHAIN_BRANCH="${1}"
    export WL_GC_TOOLCHAIN_BRANCH
else
    WL_GC_TOOLCHAIN_BRANCH="main"
fi
printf "INFO: Toolchain branch is %s.\n" "$WL_GC_TOOLCHAIN_BRANCH"

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
cd "$WORKSPACE"

printf "INFO: Execute toolchain-management installer...\n"
"$WORKSPACE/.tmp/toolchain-management/libs/bash/install.sh" "$@"

# TODO move this to the toolchain installer project, as part of the install process
if [[ ! -d "$WORKSPACE/.tmp/toolchain-management/libs/kics" ]]
then
    printf "INFO: Install missing KICS query library\n"

    # shellcheck disable=1091
    source "$WORKSPACE/.tmp/toolchain-management/libs/bash/versions.sh"

    cd "$WORKSPACE/.tmp" # tmp dir inside toolchain project
    curl -sL --show-error "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" -o "kics.tar.gz"
    tar -xf kics.tar.gz
    cd "kics-${KICS_VER}" || exit 1

    # copy
    mkdir -p "$WORKSPACE/.tmp/toolchain-management/libs/kics"
    cp -rf "assets" "$WORKSPACE/.tmp/toolchain-management/libs/kics" || exit 1

    # wrap up
    printf "INFO: Clean up KICS resources\n"
    rm -rf "$WORKSPACE/.tmp/toolchain-management/.tmp/*.gz"
fi

cd "$WORKSPACE" || exit 1

printf "INFO: Installing Git pre-commit hooks.\n"
rm -rf "$WORKSPACE/.git/hooks/pre-commit" || true
ln -sfn "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/pre-commit.sh" "$WORKSPACE/.git/hooks/pre-commit"

printf "INFO: Installing Git pre-push hooks.\n"
rm -rf "$WORKSPACE/.git/hooks/pre-push" || true
ln -sfn "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/pre-push.sh" "$WORKSPACE/.git/hooks/pre-push"

# Post-landing reset
cd "$WORKSPACE" || exit 1

printf "INFO: ...Done.\n"
