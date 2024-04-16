#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
# shellcheck source=/home/jenkins/
source "$SHELL_PROFILE"

# Debian (deprecated)
function apt_systems() {
    printf "INFO: Updating and installing system tools via apt. \n"

    # https://gist.github.com/sebastianwebber/2c1e9c7df97e05479f22a0d13c00aeca

    # add repo and signing key
    VERSION_ID=$(lsb_release -r | cut -f2)

    echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel-kubic-libcontainers-stable.list

    curl -Ls https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_$VERSION_ID/Release.key | sudo apt-key add -

    sudo apt-get update -y

    sudo apt-get install -y \
        buildah \
        ca-certificates \
        curl \
        gcc \
        gcc-c++ \
        git \
        git-lfs \
        gnupg \
        gnupg2 \
        jq \
        libbz2-dev \
        parallel \
        podman \
        tree \
        unzip

    # fix known issue 11745 with [machine] entry
    sudo sed -i 's/^\[machine\]$/#\[machine\]/' /usr/share/containers/containers.conf

    sudo apt-get update -y

    # source https://github.com/pyenv/pyenv/wiki#suggested-build-environment
    printf "INFO: System packages for python via pyenv.\n"
        sudo apt install -y \
            build-essential \
            libbz2-dev \
            libffi-dev \
            liblzma-dev \
            libncursesw5-dev \
            libreadline-dev \
            libsqlite3-dev curl \
            libssl-dev \
            libxml2-dev \
            libxmlsec1-dev \
            tk-dev \
            xz-utils \
            zlib1g-dev 
}

# NOTE: Use curl installs as a last resort as we can not always validate the security of the install.sh from the vendor.
function curl_installers() {
    if [[ ( ! $(which xeol) && $XEOL_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing xeol.\n"
        # TODO migrate to ./installers
        curl -sSfL https://raw.githubusercontent.com/xeol-io/xeol/main/install.sh | sudo sh -s -- -b "$BIN_DIR" "v$XEOL_VER"
    fi
}

# CentOS/Fedora (prefered)
function dnf_systems() {
    printf "INFO: Updating and installing system tools via dnf.\n"

    # Fedora 38, 39
    sudo dnf update -y
    sudo dnf install -y \
        bzip2 \
        bzip2-devel \
        ca-certificates \
        curl \
        gcc \
        gcc-c++ \
        git \
        git-lfs \
        gnupg \
        gnupg2 \
        htop \
        jq \
        libffi-devel \
        lzma \
        make \
        ncurses \
        openssl \
        openssl-devel \
        parallel \
        patch \
        podman \
        readline \
        readline-devel \
        skopeo \
        sqlite \
        sqlite-devel \
        sqlite3 \
        tk-devel \
        tree \
        unzip \
        xz-devel \
        zlib-devel
}

# DEPRECATED 2024-03-11. Use intstall_dnf()
function yum_systems() {
    printf "INFO: Updating and installing system tools via yum.\n"

    # RHEL (Jenkins worker)
    sudo yum update -y
    sudo yum install -y \
        bzip2 \
        bzip2-devel \
        ca-certificates \
        curl \
        gcc \
        gcc-c++ \
        git \
        git-lfs \
        gnupg \
        gnupg2 \
        htop \
        jq \
        libffi-devel \
        lzma \
        make \
        ncurses \
        openssl \
        openssl-devel \
        parallel \
        patch \
        podman \
        readline \
        readline-devel \
        skopeo \
        sqlite \
        sqlite-devel \
        sqlite3 \
        tk-devel \
        tree \
        unzip \
        xz-devel \
        zlib-devel
}

function install_goenv() {
    printf "INFO: install_goenv.\n"
    # shellcheck disable=SC1090
    source "$SHELL_PROFILE"

    if [[ ! $(which goenv) ]]
    then
        printf "INFO: Installing goenv to %s to enable Go support\n" ~/.goenv
        rm -rf ~/.goenv || true
        git clone --quiet "https://github.com/syndbg/goenv.git" ~/.goenv

        printf "INFO: Add goenv bin dir to PATH via %s.\n" "$SHELL_PROFILE"
        # shellcheck disable=SC2016
        {
            echo 'export GOENV_ROOT="$HOME/.goenv"'
            echo 'export PATH="$GOENV_ROOT/bin:$GOENV_ROOT/shims:$PATH"'
            echo 'eval "$(goenv init -)"'
        } >> "$SHELL_PROFILE"

        # shellcheck disable=SC1090
        source "$SHELL_PROFILE"

        goenv install --force --quiet "$GO_VER"
        goenv global "$GO_VER"
    fi

    if [[ "$UPDATE" == "true" ]]        
    then
        printf "INFO: Updating Golang via goenv to version %s\n" "$GO_VER"

        OLD_PWD="$(pwd)"
        cd ~/.goenv || exit 1

        git reset master --hard
        git fetch --all --tags
        git checkout "$GOENV_VER"

        # shellcheck disable=SC1090
        source "$SHELL_PROFILE"

        goenv install --force --quiet "$GO_VER"
        goenv global "$GO_VER"

        cd "$OLD_PWD" || exit 1
    fi

    # -----

    which goenv
    goenv version
    which go
    go version
}

# https://github.com/pyenv/pyenv
function install_pyenv() {
    printf "INFO: install_pyenv.\n"
    # shellcheck disable=SC1090
    source "$SHELL_PROFILE"

    if [[ ! $(which pyenv) ]]
    then
        printf "INFO: Installing pyenv to %s to enable Python support\n" "~/.pyenv"
        rm -rf ~/.pyenv || true
        ./libs/bash/installers/pyenv.sh || exit 1

        printf "INFO: Add pyenv bin dir to PATH via %s.\n" "$SHELL_PROFILE"
        # shellcheck disable=SC2016
        {
            echo 'export PYENV_ROOT="$HOME/.pyenv"'
            echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
            echo 'export PATH="$PYENV_ROOT/shims:$PATH"'
            echo 'eval "$(pyenv init -)"'
            echo 'eval "$(pyenv virtualenv-init -)"'
        } >> "$SHELL_PROFILE"

        # shellcheck disable=SC1090
        source "$SHELL_PROFILE"

        printf "INFO: Installing Python via pyenv.\n"
        pyenv install --force "$PYTHON_VER"

        printf "INFO: Setting Python version globally.\n"
        pyenv global "$PYTHON_VER"

        # Ensure pip is installed and up to date
        ~/.pyenv/shims/python -m ensurepip --upgrade
    fi

    if [[ "$UPDATE" == "true" ]]
    then
        printf "INFO: Updating Python via pyenv to version %s\n" "$PYENV_VER"
    
        declare OLD_PWD
        OLD_PWD="$(pwd)"
        cd ~/.pyenv || exit 1

        git reset master --hard
        git fetch --all --tags
        git checkout "v$PYENV_VER"
        cd "$OLD_PWD" || exit 1

        # shellcheck disable=SC1090
        source "$SHELL_PROFILE"

        printf "INFO: Installing Python via pyenv.\n"
        pyenv install --force "$PYTHON_VER"

        printf "INFO: Setting Python version globally.\n"
        pyenv global "$PYTHON_VER"

        # Ensure pip is installed and up to date
        ~/.pyenv/shims/python -m ensurepip --upgrade
    fi

    # -----

    which pip
    pip --version
    which python
    python --version
    which pyenv
    pyenv --version
}

function install_system_tools() {
    printf "INFO: Installing system tool from source.\n"

    if [[ $(which dnf) ]]
    then
        dnf_systems
    elif [[ $(which yum) ]]
    then
        yum_systems
    elif [[ $(which apt) ]]
    then
        apt_systems
    else
        printf "ERR: No supported system package manager found. Please consider submitting an update adding your distributions package manager.\n"
        exit 1
    fi

    git lfs track "*.iso"
    git lfs track "*.zip"
    git lfs track "*.gz"

    curl_installers
    install_goenv
    install_pyenv
}
