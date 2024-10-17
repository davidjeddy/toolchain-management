#!/bin/bash -l

# set -exo pipefail # when debuggin
set -eo pipefail

# Enforce the session load like an interactive user
# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage ./libs/bash/install.sh (optional) branch_name
# example ./libs/bash/install.sh fix/ICON-39280/connect_preprod_module_revert_to_0_36_7_due_to_kms_permissions

# Version: 0.8.3  - 2024-10-14 - FIX ./version/sh not found when running install process
# Version: 0.8.2  - 2024-10-01 - ADD logic to skip tooling install if executed on a CI pipeline host
# Version: 0.8.1  - 2024-07-16 - ADD logic to copy latest from toolchain to local project
# Version: 0.8.0  - 2024-06-19 - UPDATED `git lfs` to less error prone `git-lfs`. Ensure non-interactive sessions act like interactive sessions.
# Version: 0.7.0  - 2024-06-19 - UPDATED Toolchain source URL post migration to https://gitlab.kazan.myworldline.com/ SCM hosting
# Version: 0.6.0  - 2024-05-24 - UPDATED Git hook symlink creation - David J Eddy
# Version: 0.5.11 - 2024-05-06 - ADD Git feature checks - David J Eddy
# Version: 0.5.10 - 2024-04-22
# Version: 0.5.8  - 2024-03-19

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

# Troubleshooting reminder
if [[ ! $BUILD_URL && $(whoami) == "jenkins" ]]
then
    printf "WARN: Are you logged in as the Jenkins user trying to troubleshoot the pipeline? You MUST 'export BUILD_URL=\"some_value\"' to emulate a automated pipeline execution.\n"
    exit 0
fi
if [[ ! $CI_JOB_URL && $(whoami) == "gitlab" ]]
then
    printf "WARN: Are you logged in as the Jenkins user trying to troubleshoot the pipeline? You MUST 'export CI_JOB_URL=\"some_value\"' to emulate a automated pipeline execution.\n"
    exit 0
fi

# DO NOT execute the install process if running in CI pipeline.
# BUILD_URL is for Jenkins, (CI_JOB_URL)[] is for (GitLab)[https://docs.gitlab.com/ee/ci/variables/predefined_variables.html]
if [[ ! $BUILD_URL && ! $CI_JOB_URL ]]
then
    printf "INFO: Execute toolchain-management tooling installer...\n"
    cd "$WORKSPACE/.tmp/toolchain-management"
    # We want to be inside the toolchain to support local dir dependencies
    ./libs/bash/install.sh "$@"
    cd "$WORKSPACE"
fi

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
