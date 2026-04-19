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

    # 'cause curl can not save the output if the target dir does not exist'
    if [[ ! -d .tmp/ ]]
    then
        mkdir -p ".tmp" || exit 1
    fi

    # Most universal install process
    # https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    curl \
        --silent \
        --output ".tmp/awscliv2.zip" \
        "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip"
    unzip -o .tmp/awscliv2.zip -d .tmp/
    sudo .tmp/aws/install \
        --bin-dir /usr/local/bin \
        --install-dir /usr/local/aws-cli \
        --update
    rm .tmp/awscliv2.zip || exit 1
    rm -rf .tmp/aws || exit 1

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
