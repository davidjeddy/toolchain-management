#!/usr/bin/env bash

set -e
    
# aws - ssm-session-manager plugin
# https://stackoverflow.com/questions/12806176/checking-for-installed-packages-and-if-not-found-install
printf "INFO: Processing AWS session-manager-plugin.\n"
# shellcheck disable=SC2126
if [[ $(which dnf) && $(dnf list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
then
    echo "INFO: Installing AWS CLI session-manager-plugin via dnf system package manager.";
    # Fedora
    if [[ $(uname -m) == "x86_64" ]]
    then
        ## arm64
        sudo dnf install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
    elif [[ $(uname -m) == "aarch64" ]]
    then
        ## amd64
        sudo dnf install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_arm64/session-manager-plugin.rpm"
    else
        prinf "ALERT: Unable to determine CPU architecture for AWS session-manager-plugin.\n"
    fi
elif [[ $(which yum) && $(yum list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
then
    # RHEL
    echo "INFO: Installing AWS CLI session-manager-plugin via yum system package manager.";
    # We have to manually remove the symlink to make the pacakge install idempotent
    sudo rm "/usr/local/bin/session-manager-plugin" || true
    sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
elif [[ $(which apt) && $(apt list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
then
    # Debian
    echo "INFO: Installing AWS CLI session-manager-plugin via apt system package manager.";
    echo "WARN: Actually, no. Please submit MR to support Debian based systems.";
    exit 1
fi

# https://pypi.org/project/onelogin-aws-cli/
# `onelogin-aws-login` provided by package `onelogin-aws-cli`
if [[ ! $(which onelogin-aws-login) || $(onelogin-aws-login --version) != "${ONELOGIN_AWS_CLI_VER}" ]]
then
    printf "INFO: Remove old onelogin-aws-cli if it exists.\n"
    pip uninstall -y onelogin-aws-cli || true

    # We always want the latest vesrsion of tools installed via pip
    printf "INFO: Installing onelogin-aws-cli compliance tool.\n"
    pip install -U onelogin-aws-cli=="$ONELOGIN_AWS_CLI_VER"
fi

onelogin-aws-login --version
echo "onelogin-aws-cli $(pip show onelogin-aws-cli)"

# -----

printf "INFO: Installing kics. (If the process hangs, try disablig proxy/firewalls/vpn. Golang needs the ability to download packages via ssh protocol.\n"
if [[ ! $(which kics) || ! -d ".tmp/kics-${KICS_VER}" ]]
then
    printf "INFO: Downloading kics.\n"

    mkdir -p ".tmp" || exit 1
    cd ".tmp" || exit 1

    # obtain source archive
    curl --location --silent --show-error "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" -o "kics.tar.gz"
    tar -xf kics.tar.gz
    cd ../
fi

# build executable if needed
if [[ ! $(which kics) ]]
then
    printf "INFO: Build and Install kics.\n"

    cd ".tmp/kics-${KICS_VER}" || exit 1
    # Make sure GO >=1.11 modules are enabled
    declare GO111MODULE
    export GO111MODULE="on"
    goenv exec go mod download -x
    goenv exec go build -o bin/kics cmd/console/main.go

    sudo install bin/kics /usr/local/bin/
    cd "../../" || exit 1
fi

# Always update KICS query library during an install
rm -rf "libs/kics/assets" || true
mkdir -p "libs/kics/assets" || exit 1
cp -rf ".tmp/kics-${KICS_VER}/assets" "libs/kics/" || exit 1

which kics
kics version
