#!/bin/bash

# System Tools (packages)
SYSTEM_TOOLS="awscli \
    ca-certificates \
    curl \
    git \
    gnupg \
    golang-go \
    jq \
    unzip"

# usage install_systm_tools
function install_systm_tools() {
    if [[ $(which apt) ]]
    then
        printf "INFO: Updating and installing system tools via apt. \n"
        printf "INFO: When prompted, please provide requested credentials. \n"
        sudo apt-get update -y
        # shellcheck disable=SC2086
        sudo apt-get install -y \
            $SYSTEM_TOOLS

        sudo apt install -y software-properties-common
        sudo add-apt-repository ppa:deadsnakes/ppa -y
        sudo apt autoremove -y
    elif [[ $(which yum) ]]
    then
        printf "INFO: Updating and installing system tools via yum.\n"
        printf "INFO: When prompted, please provide requested credentials. \n"
        sudo yum update -y
        # shellcheck disable=SC2086
        sudo yum install -y \
            $SYSTEM_TOOLS \
            yum-utils \
            zlib-devel
    else
        printf "INFO: Unable to determine system package manager, exiting.\nPlease consider submitting an update to the script for your distributions package manager."
        exit 1
    fi

    if [[ ! $(which python3) ]]
    then
        printf "INFO: Installing Python3 from source.\n"
        cd .tmp || true
        curl -L https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tgz -o Python-3.8.12.tgz
        tar xzf Python-3.8.12.tgz
        cd Python-3.8.12 || true
        ./configure --enable-optimizations
        sudo make altinstall

        printf "ALERT:You may need to create a symlink from the python3.x.y binary to python3.\n"

        cd "../" || true
    fi

    git --version
    pip3 --version
    python3 --version
}
