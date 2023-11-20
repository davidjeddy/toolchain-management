#!/bin/bash -e

# See header of terraform-toolchain-management project./libs/bash/install.sh for advanced argument options

# usage install.sh --platform [STRING] --arch [STRING]
# example install.sh --platform linux --arch amd64

## configuration

if [[ $WL_TF_DEPLOYMENT_LOG == "TRACE" ]]
then 
    set -x
fi

## vars

declare THIS_WORKSPACE
THIS_WORKSPACE=$(git rev-parse --show-toplevel)
printf "INFO: THIS_WORKSPACE %s\n" "${THIS_WORKSPACE}"

# pre-flight checks and resets

printf " INFO: Removing existing .tmp if exists\n"
rm -rf "$THIS_WORKSPACE/.tmp" || exit 12

## functions

## logic

# clone toolchain locally if missing
rm -rf "$THIS_WORKSPACE/.tmp/toolchain-management" || true
printf "INFO: Clone toolchain-management project locally into %s/.tmp\n" "$(pwd)"
git clone --quiet git@gitlab.test.igdcs.com:cicd/terraform/tools/toolchain-management.git "$THIS_WORKSPACE/.tmp/toolchain-management"

printf "INFO: execute toolchain-management installer...\n"
"$THIS_WORKSPACE/.tmp/toolchain-management/libs/bash/install.sh" "$@"

# TODO move this to the toolchain installer project, as part of the install process
if [[ ! -d "$THIS_WORKSPACE/.tmp/toolchain-management/libs/kics" ]]
then
    printf "INFO: Install miissing KICS query library\n"

    # shellcheck disable=1091
    source "$THIS_WORKSPACE/.tmp/toolchain-management/libs/bash/versions.sh"

    cd "$THIS_WORKSPACE/.tmp" # tmp dir inside toolchain project
    curl -sL --show-error "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" -o "kics.tar.gz"
    tar -xf kics.tar.gz
    cd "kics-${KICS_VER}" || exit 1

    # copy
    mkdir -p "$THIS_WORKSPACE/.tmp/toolchain-management/libs/kics"
    cp -rf "assets" "$THIS_WORKSPACE/.tmp/toolchain-management/libs/kics" || exit 1

    # wrap up
    printf "INFO: Clean up KICS resources\n"
    rm -rf "$THIS_WORKSPACE/.tmp/toolchain-management/.tmp/*.gz"
fi

cd "$THIS_WORKSPACE" || exit 1

printf "ALERT: Installing Git pre-commit hooks.\n"
rm -rf "$THIS_WORKSPACE/.git/hooks/pre-commit" || true
ln -sfn "$THIS_WORKSPACE/.tmp/toolchain-management/libs/bash/git/pre_commit.sh" "$THIS_WORKSPACE/.git/hooks/pre-commit"

# Post-landing reset
cd "$THIS_WORKSPACE" || exit 1

printf "INFO: Project installation completed successfully.\n"
