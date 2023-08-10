#!/bin/bash

function apt_systems() {
    printf "INFO: Updating and installing system tools via apt. \n"
    sudo apt-get update -y

    # shellcheck disable=SC2086
    sudo apt-get install -y \
        buildah \
        ca-certificates \
        curl \
        gnupg \
        jq \
        libbz2-dev \
        parallel \
        podman \
        unzip

    # source https://number1.co.za/how-to-build-python-3-from-source-on-ubuntu-22-04/
    printf "INFO: System packages for Python3.\n"
    sudo apt install -y \
        buildah \
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
        parallel \
        podman \
        python3-distutils \
        tk-dev
}

# NOTE: Use curl installs as a last resort as we can not always validate the security of the install.sh from the vendor.
function curl_installers() {
    if [[ ( ! $(which xeol) && $XEOL_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing xeol.\n"
        curl -sSfL https://raw.githubusercontent.com/xeol-io/xeol/main/install.sh | sudo sh -s -- -b "$BIN_DIR" "v$XEOL_VER"
    fi
}

function yum_systems() {
    printf "INFO: Updating and installing system tools via yum.\n"
    sudo yum update -y

    if [[ $(cat "/etc/redhat-release") == *Fedora* ]]
    then
        # Fedora (Developer DWS Workstations Linux VM)
        sudo yum install -y \
            bzip2 \
            bzip2-devel \
            ca-certificates \
            curl \
            gnupg \
            jq \
            libffi-devel \
            parallel \
            podman \
            python3-distutils-extra \
            unzip \
            yum-utils \
            zlib-devel
    else
        # Red Hat (Jenkins worker)
        sudo yum install -y \
            bzip2 \
            bzip2-devel \
            ca-certificates \
            curl \
            gnupg \
            jq \
            libffi-devel \
            parallel \
            podman \
            python3-distutils \
            unzip \
            yum-utils \
            zlib-devel
    fi
}

function install_goenv() {
    if [[ ( ! $(which goenv) && $GOENV_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing goenv to %s \n" "$HOME/.goenv"
        cd "$HOME" || exit 1
        rm -rf "$HOME/.goenv" || true
        git clone --quiet "https://github.com/syndbg/goenv.git" "$HOME/.goenv"

        # shellcheck disable=SC2143
        if [[ ! $(grep "export PATH=\$PATH:\$HOME/.goenv/bin" "$SHELL_PROFILE") ]]
        then
            printf "INFO: Add goenv bin dir to PATH via %s.\n" "$SHELL_PROFILE"
            {
                echo "export PATH=\$PATH:\$HOME/.goenv/bin"
                echo "export GOENV_ROOT=\$HOME/.goenv"
                echo "eval $("$HOME"/.goenv/bin/goenv init -)"
            } >> "$SHELL_PROFILE"
        fi

        #shellcheck disable=SC1090
        source "$SHELL_PROFILE"

        goenv install --force "$GO_VER"

    elif [[ -d "$HOME/.goenv" && $GOENV_VER && "$UPDATE" == "true" ]]
    then
        printf "INFO: Updating goenv.\n"
        cd "$HOME/.goenv" || exit
        git reset master --hard
        git fetch --all --tags
        git checkout "$GOENV_VER"

        goenv install --force "$GO_VER"

        cd "$PROJECT_ROOT" || exit 1
    fi

    goenv global "$GO_VER"
}

function install_python3() {

    printf "INFO: Processing Python system tools.\n"

    if [[ ( ! $(which python3) && "$PYTHON_VER" ) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Python3 runtime not detected or needs updated.\n"
        curl -sL --show-error "https://www.python.org/ftp/python/$PYTHON_VER/Python-$PYTHON_VER.tgz" -o "Python-$PYTHON_VER.tgz"
        tar xzf "Python-$PYTHON_VER.tgz"
        cd "Python-$PYTHON_VER" || exit 1
        ./configure \
            --bindir="$BIN_DIR" \
            --enable-optimizations
        sudo make install

        {
            printf "INFO: Creating symlink from %s/python3.8 binary to %s/python3.\n" "$BIN_DIR" "$BIN_DIR"
            sudo ln -sfn "$BIN_DIR/python3.8" "$BIN_DIR/python3"
        } || {
            printf "CRITICAL: Could NOT create symlink from %s/python3.8 to %s/python3. Exiting with error" "$BIN_DIR" "$BIN_DIR"
            exit 1
        }

        cd "../" || exit 1
        sudo rm -rf Python*
    fi
}

function install_pip() {

    printf "INFO: Processing pip system tools.\n"

    if [[ ( ! $(which pip) ) || "$UPDATE" == "true" ]]
    then
        printf "INFO: pip package manager not detected or update requested.\n"
        # Because pipelines do not have a full shell, be sure to include the PATH to the Python binaries
        # shellcheck disable=SC2155
        export PATH=$PATH:/home/$(whoami)/.local/bin

        # For Python3/pip site-packages at the user scope
        # shellcheck disable=SC2143
        if [[ ! $(grep "export PATH=\$PATH:\$HOME/.local/bin" "$SHELL_PROFILE") ]]
        then
            printf "INFO: Add pip site-package to PATH"
            echo "export PATH=\$PATH:\$HOME/.local/bin" >> "$SHELL_PROFILE"
            #shellcheck disable=SC1090
            source "$SHELL_PROFILE"
        fi

        printf "INFO: Removing existing site-packages at %s\n" "/home/$(whoami)/.local/lib/python$PYTHON_MINOR_VER/site-packages"
        rm -rf "/home/$(whoami)/.local/lib/python$PYTHON_MINOR_VER/site-packages"

        printf "INFO: Download pip installer.\n"
        curl -sL --show-error "https://bootstrap.pypa.io/get-pip.py" -o get-pip.py

        printf "INFO: Install pip via python3.\n"
        python3 get-pip.py

        printf "INFO: Update pip via itself.\n"

        python3 -m pip install --upgrade --force-reinstall pip
        sudo rm -rf get-pip.py
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
        # Needed for some PIP packages the build correctly
        pip install Cmake
    else
        printf "CRITICAL: Unable to determine system package manager, exiting.\n"
        printf "INFO: Please consider submitting an update adding your distributions package manager.\n"
        exit 1
    fi

    curl_installers

    install_goenv

    # python before pip
    install_python3
    install_pip

    goenv version
    goenv exec go version
    pip --version
    python3 --version

    xeol version
}
