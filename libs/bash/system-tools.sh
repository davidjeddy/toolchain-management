#!/bin/bash

function apt_systems() {
    printf "INFO: Updating and installing system tools via apt. \n"
    sudo apt-get update -y

    # shellcheck disable=SC2086
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        golang-go \
        jq \
        unzip
}

function yum_systems() {
    printf "INFO: Updating and installing system tools via yum.\n"
    sudo yum update -y

    # shellcheck disable=SC2086
    sudo yum install -y \
        ca-certificates \
        curl \
        gnupg \
        golang-go \
        jq \
        unzip \
        yum-utils \
        zlib-devel
}

# installing Python3 and pip3
function install_python3_and_pip3() {

    printf "INFO: Processing SYSTEM tools.\n"

    curl -L "https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz" -o "Python-${PYTHON_VER}.tgz"
    tar xzf "Python-${PYTHON_VER}.tgz"
    cd "Python-${PYTHON_VER}" || exit 1
    ./configure --enable-optimizations
    sudo make altinstall
    rm -rf Python*

    printf "ALERT:You may need to create a symlink from the /path/to/binaries/python3.x.y to /path/to/binaries/python3.\n"

    cd "../" || true
}

# usage install_systm_tools
function install_systm_tools() {

    printf "INFO: Installing system tools.\n"

    if [[ $(which apt) ]]
    then
        apt_systems
    elif [[ $(which yum) ]]
    then
        yum_systems
    else
        printf "CRITICAL: Unable to determine system package manager, exiting.\n"
        printf "INFO: Please consider submitting an update adding your distributions package manager.\n"
        exit 1
    fi

    if [[ ! ($(which python3) || ! $(which pip3)) || "${UPDATE}" == "true" ]]
    then
        install_python3_and_pip3
    fi

    pip3 --version
    python3 --version
}
