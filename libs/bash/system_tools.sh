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
        libffi-dev \
        libgdbm-compat-dev \
        libgdbm-dev \
        liblzma-dev \
        libncurses-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        tk-dev
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
        libffi-dev \
        libssl-dev \
        unzip \
        yum-utils \
        zlib-devel
}

function install_golang() {

    printf "INFO: Processing Golang system tool from source.\n"

    if [[ ( !  $(which go) && "$GOLANG_VER" ) || "$UPDATE" == "true" ]]
    then
        curl -sL --show-error "https://go.dev/dl/go${GOLANG_VER}.${PLATFORM}-${ARCH}.tar.gz" -o "go${GOLANG_VER}.${PLATFORM}-${ARCH}.tar.gz"
        tar -xf "go${GOLANG_VER}.${PLATFORM}-${ARCH}.tar.gz"
        install --target-directory="$BIN_DIR" go/bin/go
        rm -rf go* || exit 1

        # shellcheck disable=SC2143
        if [[ ! $(grep "export GOROOT" "$SHELL_PROFILE") ]]
        then
            printf "INFO: Add GOROOT to PATH via %s.\n" "$SHELL_PROFILE"
            echo "export GOROOT=$BIN_DIR" >> "$SHELL_PROFILE"
            #shellcheck disable=SC1090
            source "$SHELL_PROFILE"
        fi
    fi
}

function install_python3() {

    printf "INFO: Processing Python system tools.\n"

    if [[ ( !  $(which python3) && "$PYTHON_VER" ) || "$UPDATE" == "true" ]]
    then
        curl -sL --show-error "https://www.python.org/ftp/python/$PYTHON_VER/Python-$PYTHON_VER.tgz" -o "Python-$PYTHON_VER.tgz"
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
            printf "CRITICAL: Could NOT create symlink from %s/python3.8 to %s/python3. Exiting with error" "$BIN_DIR" "$BIN_DIR"
            exit 1
        } 

        cd "../" || true
    fi
}

function install_pip3() {

    if [[ ( ! $(which pip3) ) || "$UPDATE" == "true" ]]
    then
        # Because pipelines do not have a full shell, be sure to include the PATH to the Python binaries
        # shellcheck disable=SC2155
        export PATH=$PATH:/home/$(whoami)/.local/bin

        # For Python3/pip3 site-packages at the user scope
        # shellcheck disable=SC2143
        if [[ ! $(grep "export PATH=\$PATH:\$HOME/.local/bin" "$SHELL_PROFILE") ]]
        then
            printf "INFO: Add pip3 site-package to PATH"
            echo "export PATH=\$PATH:\$HOME/.local/bin" >> "$SHELL_PROFILE"
            #shellcheck disable=SC1090
            source "$SHELL_PROFILE"
        fi

        printf "INFO: Download pip3 installer.\n"
        curl -sL --show-error "https://bootstrap.pypa.io/get-pip.py" -o get-pip.py

        printf "INFO: Install pip3 via python3.\n"
        python3 get-pip.py

        printf "INFO: Update pip3 via itself.\n"
        python3 -m pip install --upgrade pip
    fi
}

function install_system_tools() {

    printf "INFO: Installing system tool from source.\n"

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

    install_golang
    install_python3
    install_pip3

    sudo rm -rf Python*
    sudo rm -rf get-pip.py

    go version
    pip3 --version
    python3 --version
}
