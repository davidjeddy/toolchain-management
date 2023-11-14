#!/bin/bash

function apt_systems() {
    printf "INFO: Updating and installing system tools via apt. \n"

    # https://gist.github.com/sebastianwebber/2c1e9c7df97e05479f22a0d13c00aeca
    # installl buildah in ubuntu
    # prereq packages

    # add repo and signing key
    VERSION_ID=$(lsb_release -r | cut -f2)

    echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel-kubic-libcontainers-stable.list

    curl -Ls https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_$VERSION_ID/Release.key | sudo apt-key add -

    sudo apt-get update

    # install buildah and podman
    sudo apt install buildah podman -y

    # fix known issue 11745 with [machine] entry
    sudo sed -i 's/^\[machine\]$/#\[machine\]/' /usr/share/containers/containers.conf

    sudo apt-get update -y

    # shellcheck disable=SC2086
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
        tree \
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
            gcc \
            gcc-c++ \
            git \
            git-lfs \
            gnupg \
            gnupg2 \
            jq \
            libffi-devel \
            parallel \
            podman \
            python3-distutils-extra \
            tree \
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
            gcc \
            gcc-c++ \
            git \
            git-lfs \
            gnupg \
            gnupg2 \
            jq \
            libffi-devel \
            parallel \
            podman \
            python3-distutils \
            tree \
            unzip \
            yum-utils \
            zlib-devel
    fi

    # Install Git 2.x from 
    git lfs track "*.iso"
    git lfs track "*.zip"
    git lfs track "*.gz"
}

function install_goenv() {
    if [[ ( ! $(which go) && $GO_VER && $GOENV_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing goenv to %s to enable Go\n" "$HOME/.goenv"
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

    elif [[ ( $(which go) && $GO_VER && $GOENV_VER ) ]]
    then
        printf "INFO: Updating Go via goenv.\n"
        cd "$HOME/.goenv" || exit 1
        git reset master --hard
        git fetch --all --tags
        git checkout "$GOENV_VER"

        goenv install --force "$GO_VER"
    fi

    goenv global "$GO_VER"
}

function install_python3() {

    printf "INFO: Processing Python system tools.\n"

    if [[ ( ! $(which python3) && "$PYTHON_VER" ) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Python3 runtime not detected or needs updated.\n"

        # TODO Replace this all with pyenv
        curl -sL --show-error "https://www.python.org/ftp/python/$PYTHON_VER/Python-$PYTHON_VER.tgz" -o "Python-$PYTHON_VER.tgz"
        tar xzf "Python-$PYTHON_VER.tgz"
        cd "Python-$PYTHON_VER" || exit 1
        sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
        ./configure \
            --bindir="$BIN_DIR" \
            --enable-optimizations \
            --prefix="$BIN_DIR"
        sudo make clean || true
        sudo make altinstall

        # If the build was successful the following should exit without errors
        python -m ssl

        {
            printf "INFO: Creating symlink from %s/python3.8 binary to %s/python%s.\n" "$BIN_DIR" "$BIN_DIR" "$PYTHON_MAJOR_VER"
            sudo ln -sfn "$BIN_DIR/python${PYTHON_MINOR_VER}" "$BIN_DIR/python${PYTHON_MAJOR_VER}"
        } || {
            printf "CRITICAL: Could NOT create symlink from %s/python%s to %s/python%s. Exiting with error" "$BIN_DIR" "$PYTHON_MAJOR_VER" "$BIN_DIR" "$PYTHON_MINOR_VER"
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
        rm -rf "/home/$(whoami)/.local/lib/python$PYTHON_MINOR_VER/site-packages" || true

        printf "INFO: Download pip installer.\n"
        curl -sL --show-error "https://bootstrap.pypa.io/get-pip.py" -o get-pip.py

        printf "INFO: Install pip via python3.\n"
        python3 get-pip.py

        printf "INFO: Update pip via itself.\n"

        python3 -m pip install --upgrade --force-reinstall pip
        sudo rm -rf get-pip.py

        # Needed for some PIP packages the build correctly
        pip install Cmake
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

    curl_installers

    install_goenv

    # python before pip
    install_python3
    install_pip

    goenv version
    goenv exec go version
    pip --version
    python3 --version

    # The folowing line causes "2023/09/12 14:27:39 unsupported git url: git@gitlab.test.igdcs.com:cicd/terraform/deployments.git" error, not sure why
    # Validated in localhost fedora 38 and Jenkins RHEL 7
    # xeol version
}
