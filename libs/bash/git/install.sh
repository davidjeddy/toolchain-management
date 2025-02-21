#!/bin/bash -l

set -eo pipefail

# Enforce the session load like an interactive user
# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# example ./libs/bash/install.sh main 3
# example ./libs/bash/install.sh fix/ICON-39280/connect_preprod_module_revert_to_0_36_7_due_to_kms_permissions 2
# example ./libs/bash/install.sh fix/PROS-XXXXX/tool-version-update 1
# usage ./libs/bash/install.sh (optional) BRANCH_NAME (optional) PROJECT_TYPE
# version: 0.9.0  - 2025-02-11 - ADD `PROJECT_TYPE` selection logic
# version: 0.9.0  - 2025-02-11 - UPDATED `GC_WL_TOOLCHAIN_DEV` logic to be easier to reason about
# version: 0.9.0  - 2025-02-11 - MOVED muc of the logic into fn()'s for better abstraction
# version: 0.8.4  - 2024-10-28 - ADD check for `$WORKSPACE/.git/hooks` before creating symlinks
# version: 0.8.3  - 2024-10-28 - ADD ENV VAR GC_WL_TOOLCHAIN_DEV to enable easier localhost development
# version: 0.8.2  - 2024-10-01 - ADD logic to skip tooling install if executed on a CI pipeline host
# version: 0.8.1  - 2024-07-16 - ADD logic to copy latest from toolchain to local project
# version: 0.8.0  - 2024-06-19 - UPDATED `git lfs` to less error prone `git-lfs`. Ensure non-interactive sessions act like interactive sessions.
# version: 0.7.0  - 2024-06-19 - UPDATED Toolchain source URL post migration to https://gitlab.kazan.myworldline.com/ SCM hosting
# version: 0.6.0  - 2024-05-24 - UPDATED Git hook symlink creation
# version: 0.5.11 - 2024-05-06 - ADD Git feature checks
# version: 0.5.10 - 2024-04-22
# version: 0.5.8  - 2024-03-19

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
if [[ "$1" ]]
then
    WL_GC_TOOLCHAIN_BRANCH="${1}"
fi
export WL_GC_TOOLCHAIN_BRANCH
printf "INFO: Toolchain branch is %s\n" "$WL_GC_TOOLCHAIN_BRANCH"

# Set project type if provided
declare PROJECT_TYPE
PROJECT_TYPE=0
if [[ "$2" ]]
then
    PROJECT_TYPE="${2}"
fi
export PROJECT_TYPE
printf "INFO: Project default type is %s\n" "$PROJECT_TYPE"

## functions

# ARG 1 STRING Path to the project workspace
# RETURN 1 INT
function cicdPipelineOverrides() {
    printf "INFO: Starting cicdPipelineOverrides()\n"
    local WORKSPACE="$1"

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
    # (BUILD_URL)[https://wiki.jenkins.io/display/JENKINS/Building+a+software+project] is for (Jenkins)[https://www.jenkins.io/]
    # (CI_JOB_URL)[https://docs.gitlab.com/ee/ci/variables/] is for (GitLab)[https://docs.gitlab.com/]
    if [[ ! $BUILD_URL && ! $CI_JOB_URL ]]
    then
        printf "INFO: Execute toolchain-management tooling installer...\n"
        "$WORKSPACE/.tmp/toolchain-management/libs/bash/install.sh" "$@"
    fi

    return 0
}

# ARG 1 STRING Path to the project workspace
# RETURN 1 INT
function gitCheckout() {
    printf "INFO: Starting cicdPipelineOverrides()\n"
    local WORKSPACE="$1"

    if [[ $GC_WL_TOOLCHAIN_DEV ]]
    then
        printf "WARN: GC_WL_TOOLCHAIN_DEV is set, using localhost version of Toolchain."
    else
        # Override value not set, do normal
        printf "INFO: Removing existing .tmp if exists.\n"
        rm -rf "$WORKSPACE/.tmp" || exit 1
        printf "INFO: Clone toolchain-management project locally into %s/.tmp\n" "$(pwd)"
        git clone --quiet https://gitlab.kazan.myworldline.com/cicd/terraform/tools/toolchain-management.git "$WORKSPACE/.tmp/toolchain-management"

        # Even if main, checkout anyways
        cd "$WORKSPACE/.tmp/toolchain-management"
        git checkout "$WL_GC_TOOLCHAIN_BRANCH" --force
        cd "$WORKSPACE" || exit 1
    fi

    return 0
}

# RETURN 1 INT
function gitFeatureConfiguration() {
    printf "INFO: Starting gitFeatureConfiguration()\n"

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

    return 0
}

# ARG 1 STRING Path to the project workspace
# ARG 2 INT Type of project
# RETURN INT
function gitHookSelection() {
    printf "INFO: Starting gitHookSelection()\n"
    local WORKSPACE="$1"
    local PROJECT_TYPE="$2"

    # Ensure $WORKSPACE/.git/hook dir exists
    if [[ ! -d "$WORKSPACE/.git/hooks" ]]
    then
        mkdir -p "$WORKSPACE/.git/hooks" || exit 1
    fi

    # what kind of project is this?
    if [[ "$PROJECT_TYPE" == "0" ]]
    then
        printf "ASK: What kind of project is this: 1) Bash 2) Container 3) IAC? "
        read -r PROJECT_TYPE
    fi
    printf "INFO: PROJECT_TYPE selected: %s\n" "$PROJECT_TYPE"

    local GIT_HOOK_SOURCE_PATH
    # Alphabetical sort
    case $PROJECT_TYPE in
    1)
        printf "INFO: Installing BASH Git hooks.\n"
        GIT_HOOK_SOURCE_PATH="bash_hooks"
        ;;
    2)
        printf "INFO: Installing CONTAINER Git hooks.\n"
        GIT_HOOK_SOURCE_PATH="container_hooks"
        ;;
    3)
        printf "INFO: Installing IAC Git hooks.\n"
        GIT_HOOK_SOURCE_PATH="iac_hooks"
        ;;
    *)
        printf "INFO: Installing legacy Git hooks.\n"
        GIT_HOOK_SOURCE_PATH="hooks"
        ;;
    esac

    # create symlink for each hook found
    declare GIT_HOOKS
    GIT_HOOKS=$(find "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/${GIT_HOOK_SOURCE_PATH}" -maxdepth 1 -type f | sed "s/.*\///")
    for HOOK in $GIT_HOOKS
    do
        printf "INFO: Installing Git %s hook.\n" "${HOOK}"
        rm -rf "$WORKSPACE/.git/hooks/${HOOK}" || true
        ln -sfn "$WORKSPACE/.tmp/toolchain-management/libs/bash/git/${GIT_HOOK_SOURCE_PATH}/${HOOK}" "$WORKSPACE/.git/hooks/${HOOK}"
    done

    return 0
}

## logic

# gitCheckout "$WORKSPACE"

# cicdPipelineOverrides "$WORKSPACE"

gitHookSelection "$WORKSPACE" "$PROJECT_TYPE"

gitFeatureConfiguration

# Post-flight resets
cd "$WORKSPACE" || exit 1

printf "INFO: Done. Please restart your shell session.\n"