#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

function install_additional_cloud_tools() {
    printf "INFO: starting install_additional_cloud_tools()\n"

    sudo dnf update --assumeyes
    sudo dnf install --assumeyes \
        awscli2

    # Install if missing
    if [[ ! -f "/usr/local/bin/session-manager-plugin" ]]
    then
        printf "INFO: Installing missing AWS Session Manager Plugin via rpm.\n"
        local ARCH
        ARCH="64bit"
        if [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
        then
            ARCH="arm64"
        fi

        curl \
            --location \
            --output "session-manager-plugin.rpm" \
            --show-error \
            "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_$ARCH/session-manager-plugin.rpm"
        sudo dnf install --assumeyes session-manager-plugin.rpm
        rm session-manager-plugin*
    fi
}
