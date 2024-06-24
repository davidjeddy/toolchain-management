#!/bin/bash

set -exo pipefail
# Be sure to configure session like an interactive user
# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

# usage ./libs/bash/install.sh (optional) branch_name
# example ./libs/bash/install.sh fix/ICON-39280/connect_preprod_module_revert_to_0_36_7_due_to_kms_permissions

# Version: 0.8.0  - 2024-06-19 - UPDATED `git lfs` to less error prone `git-lfs`. Ensure non-interactive sessions act like interactive sessions.
# Version: 0.7.0  - 2024-06-19 - UPDATED Toolchain source URL post migration to https://gitlab.kazan.myworldline.com/ SCM hosting
# Version: 0.6.0  - 2024-05-24 - UPDATED Git hook symlink creation - David J Eddy
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
    WORKSPACE=$(git rev-parse --show-toplevel)
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
git clone --quiet https://gitlab.kazan.myworldline.com/cicd/terraform/tools/toolchain-management.git "$WORKSPACE/.tmp/toolchain-management"

# Even if main, checkout anyways
cd "$WORKSPACE/.tmp/toolchain-management"
git checkout "$WL_GC_TOOLCHAIN_BRANCH" --force
cd "$WORKSPACE" || exit 1

printf "INFO: Execute toolchain-management installer...\n"
"$WORKSPACE/.tmp/toolchain-management/libs/bash/install.sh" "$@"

# create symlink for each hook found
declare GIT_HOOKS
GIT_HOOKS=$(find "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/hooks" -maxdepth 1 -type f | sed "s/.*\///")
for HOOK in $GIT_HOOKS
do
    printf "INFO: Installing Git %s hook.\n" "${HOOK}"
    rm -rf "$WORKSPACE/.git/hooks/${HOOK}" || true
    ln -sfn "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/hooks/${HOOK}" "$WORKSPACE/.git/hooks/${HOOK}"
done

# Git features
if [[ -f .gitattributes ]]
then
    printf "INFO: Configure Git LFS.\n"
    which git
    git --version
    which git-lfs
    git-lfs --version
    git-lfs track "*.iso"
    git-lfs track "*.zip"
    git-lfs track "*.gz"
fi

if [[ -f .gitsubmodules ]]
then
    printf "INFO: Sync Git submodules.\n"
    git submodule update --init --recursive
fi

# Post-flight resets
cd "$WORKSPACE" || exit 1

printf "INFO: Done. Please reload your shell by running the following command: \"source ~/.bashrc\".\n"
