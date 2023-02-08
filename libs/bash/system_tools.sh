#!/bin/bash

function apt_systems() {
    printf "INFO: Updating and installing system tools via apt. \n"
    sudo apt-get update -y

    # shellcheck disable=SC2086
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        jq \
        libbz2-dev \
        unzip

    # source https://number1.co.za/how-to-build-python-3-from-source-on-ubuntu-22-04/
    printf "INFO: System packages for Python3.\n"
    sudo apt install -y \
        libbz2-dev \
        libncurses-dev \
        libncursesw5-dev \
        libgdbm-dev \
        liblzma-dev \
        libsqlite3-dev \
        tk-dev \
        libgdbm-compat-dev \
        libreadline-dev
}

function yum_systems() {
    printf "INFO: Updating and installing system tools via yum.\n"
    sudo yum update -y

    # shellcheck disable=SC2086
    sudo yum install -y \
        ca-certificates \
        curl \
        gnupg \
        jq \
        libbz2-dev \
        unzip \
        yum-utils \
        zlib-devel
}

# installing Python3 and pip3
function install_python3() {

    printf "INFO: Processing SYSTEM tools.\n"

    if [[ ( !  $(which python3) && "$PYTHON_VER" ) || "$UPDATE" == "true" ]]
    then
        curl -L "https://www.python.org/ftp/python/$PYTHON_VER/Python-$PYTHON_VER.tgz" -o "Python-$PYTHON_VER.tgz"
        tar xzf "Python-$PYTHON_VER.tgz"
        cd "Python-$PYTHON_VER" || exit 1
        ./configure \
            --bindir="$BIN_DIR" \
            --enable-optimizations
        sudo make altinstall

        {
            printf "INFO: Creating symlink from %s/python3.8 binary to %s/python3.\n" "$BIN_DIR" "$BIN_DIR"
            sudo ln -sfn "$BIN_DIR/python3.8" "$BIN_DIR/python3"
        } || {
            printf "CRITICAL: Could create symlink for python3.x. Exiting with error"
            exit 1
        } 

        cd "../" || true
    fi
}

function install_pip3() {

    # For Python3/pip3 site-packages at the user scope
    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:\$HOME/.local/bin" "$SHELL_PROFILE") ]]
    then
        printf "INFO: Add pip3 site-package to PATH"
        echo "export PATH=\$PATH:\$HOME/.local/bin" >> "$SHELL_PROFILE"
        #shellcheck disable=SC1090
        source "$SHELL_PROFILE"
    fi

    if [[ ( ! $(which pip3) ) || "$UPDATE" == "true" ]]
    then
        # Because pipelines do not have a full shell, be sure to include the PATH to the Python binaries
        # shellcheck disable=SC2155
        export PATH=$PATH:/home/$(whoami)/.local/bin

        printf "INFO: Download pip3 installer.\n"
        curl -L "https://bootstrap.pypa.io/get-pip.py" -o get-pip.py

        printf "INFO: Install pip3 via python3.\n"
        python3 get-pip.py

        printf "INFO: Update pip3 via itself.\n"
        python3 -m pip install --upgrade pip
    fi
}

# usage install_system_tools
function install_system_tools() {

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

    install_python3
    install_pip3

    sudo rm -rf Python*
    sudo rm -rf get-pip.py

    pip3 --version
    python3 --version
}
