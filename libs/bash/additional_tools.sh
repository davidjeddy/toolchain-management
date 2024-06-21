#!/bin/bash

set -exo pipefail

# TODO Add these tools to Aqua registry @ https://github.com/aquaproj/aqua-registry

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
        prinf "ALERT: Unable to determine CPU architecture for Fedora distro of AWS session-manager-plugin.\n"
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
    echo "INFO: Installing AWS CLI session-manager-plugin via apt system package manager.";
    if [[ $(uname -m) == "x86_64" ]]
    then
        ## arm64
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    elif [[ $(uname -m) == "aarch64" ]]
    then
        ## amd64
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    else
        prinf "ALERT: Unable to determine CPU architecture for Debian distro of AWS session-manager-plugin.\n"
    fi
    sudo dpkg -i session-manager-plugin.deb
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

# Even with KICS being installed via Aqua we still need the query libraries

# Get version of KICS being used from aqua.yaml configuration
declare KICS_VER
KICS_VER=$(grep -w "Checkmarx/kics" aqua.yaml)
KICS_VER=$(echo "$KICS_VER" | awk -F '@' '{print $2}')
KICS_VER=$(echo "$KICS_VER" | sed ':a;N;$!ba;s/\n//g')
# shellcheck disable=SC2001
KICS_VER=$(echo "$KICS_VER" | sed 's/v//g')
printf "INFO: KICS version detected: %s\n" "$KICS_VER"

if [[ ! -d ~/.kics-installer/kics-v"${KICS_VER}" ]]
then
    printf "INFO: Installing missing KICS query library into ~/.kics-installer.\n"
    printf "WARN: If the process hangs, try disablig proxy/firewalls/vpn. Golang needs the ability to download packages via ssh protocol.\n"

    # Set PWD to var for returning later
    declare OLD_PWD
    OLD_PWD="$(pwd)"

    mkdir -p ~/.kics-installer || exit 1
    cd ~/.kics-installer || exit 1

    curl --location --silent --show-error "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" -o "kics-v${KICS_VER}.tar.gz"
    tar -xf kics-v"${KICS_VER}".tar.gz
    # we want the dir to have the `v`
    mv kics-"${KICS_VER}" kics-v"${KICS_VER}"
    # Automation can target `~/.kics-installer/target_query_libs`
    ln -sfn ./kics-v"${KICS_VER}"/assets/queries/ target_query_libs
    ls -lah

    cd "${OLD_PWD}" || exit 1
fi
