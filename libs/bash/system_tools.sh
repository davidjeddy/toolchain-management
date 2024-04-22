#!/usr/bin/env bash

set -e

# Debian (deprecated)
function apt_systems() {
    printf "INFO: Updating and installing system tools via apt. \n"

    # https://gist.github.com/sebastianwebber/2c1e9c7df97e05479f22a0d13c00aeca

    # add repo and signing key
    VERSION_ID=$(lsb_release -r | cut -f2)

    echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel-kubic-libcontainers-stable.list

    # TODO Probably want to do this via `wget`
    curl -Ls "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_$VERSION_ID/Release.key" | sudo apt-key add -

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

printf "INFO: Installing system tool using Os package manager.\n"

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
