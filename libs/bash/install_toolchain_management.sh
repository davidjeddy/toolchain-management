#!/bin/bash -e

# usage install.sh --platform linux --arch amd64
# NOTE See header of terraform-toolchain-management ./libs/bash/install.sh for advanced usage examples

## configuration

if [[ $WL_TF_DEPLOYMENT_LOG == "TRACE" ]]
then 
    set -x
fi

# pre-flight checks

declare ORIG_PWD
ORIG_PWD="$(pwd)"
declare PROJECT_ROOT
PROJECT_ROOT=$(git rev-parse --show-toplevel)

cd "$PROJECT_ROOT" || exit 1

# install toolchain-management project if missing
if [[ ! -d "$PROJECT_ROOT/.tmp/toolchain-management/.git" ]]
then
    printf "ALERT: Terraform Toolchain Management project not detected. Installing at .tmp/toolchain-management.\n"
    mkdir -p "$PROJECT_ROOT/.tmp/toolchain-management"
    cd "$PROJECT_ROOT/.tmp/toolchain-management" || exit 1
    git clone --quiet git@gitlab.test.igdcs.com:cicd/terraform/tools/toolchain-management.git .
else
    printf "INFO: Terraform Toolchain Management project detected. Updating project.\n"
    cd "$PROJECT_ROOT/.tmp/toolchain-management" || exit 1
    git checkout main --force
    git pull origin
    cd "$PROJECT_ROOT" || exit 1
fi

cd "$PROJECT_ROOT" || exit 1

if [[ $(whoami) != "jenkins" ]]
then
    # if the user is NOT `jenkins`, run the installer
    printf "INFO: Executing Terraform Toolchain Management installer.\n"
    cd "$PROJECT_ROOT/.tmp/toolchain-management" || exit 1
    ./libs/bash/install.sh --update true "$@"
elif [[ $(whoami) == "jenkins" ]]
then
    # if user IS jenkins, only install the KICS query lib
    printf "INFO: Detected execution as 'jenkins' user, assuming pipeline execution environment.\n"
    cd "$PROJECT_ROOT/.tmp/toolchain-management" || exit 1

    # shellcheck disable=1091
    source "libs/bash/versions.sh"
    printenv | sort

    printf "INFO: Installing KICS query library.\n"
    cd ".tmp/" || exit 1
    curl -sL --show-error "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" -o "kics.tar.gz"
    tar -xf kics.tar.gz
    cd "kics-${KICS_VER}" || exit 1

    # install KICS assets
    mkdir -p "$PROJECT_ROOT/.tmp/toolchain-management/libs/kics"
    cp -rf "assets" "$PROJECT_ROOT/.tmp/toolchain-management/libs/kics" || exit 1

    printf "INFO: Clean up KICS resources"
    cd "$PROJECT_ROOT/.tmp/toolchain-management/.tmp" || exit 1
    rm -rf kics*
fi

cd "$PROJECT_ROOT" || exit 1

# install git hooks if missing

if [[ ! -f ".git/hooks/pre-commit" && -f $PROJECT_ROOT/libs/bash/pre_commit.sh ]]
then
    printf "ALERT: Installing missing git pre-commit hook.\n"
    chmod +x libs/bash/*.sh -R
    cd .git/hooks
    rm -rf pre-commit
    ln -sfn "$PROJECT_ROOT/libs/bash/pre_commit.sh" "$PROJECT_ROOT/.git/hooks/pre-commit"
    cd "$PROJECT_ROOT"
fi

# Post-landing checks

cd "$ORIG_PWD" || exit 1

printf "INFO: Project installation completed successfully.\n"
