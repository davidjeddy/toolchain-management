#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# Debian
# DEPRECATED 2024-03-11
# remove on 2028-10-01
# Use intstall_dnf()
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
        libbz2-dev \
        parallel \
        podman \
        tree \
        unzip

    # fix known issue 11745 with [machine] entry
    sudo sed -i 's/^\[machine\]$/#\[machine\]/' "/usr/share/containers/containers.conf"

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

# CentOS/Fedora distros
function dnf_systems() {
    printf "INFO: Updating and installing system tools via dnf.\n"

    # Fedora 38, 39, 40
    sudo dnf update -y
    sudo dnf install -y \
        ca-certificates \
        curl \
        dmidecode \
        git \
        git-lfs \
        gnupg \
        gnupg2 \
        htop \
        parallel \
        patch \
        podman \
        skopeo \
        tk-devel \
        tree \
        unzip

    # Only for compiling Python
    sudo dnf install -y \
        automake \
        bzip2 \
        bzip2-devel \
        gcc \
        gcc-c++ \
        kernel-devel \
        libffi-devel \
        lzma \
        make \
        ncurses \
        openssl \
        openssl-devel \
        readline \
        readline-devel \
        sqlite3 \
        sqlite \
        sqlite-devel \
        xz-devel \
        zlib-devel
}

# DEPRECATED 2024-03-11
# remove on 2028-10-01
# Use intstall_dnf()
function yum_systems() {
    printf "INFO: Updating and installing system tools via yum.\n"

    # https://computingforgeeks.com/install-git-2-on-centos-7/
    if [[ $(cat /etc/redhat-release) == "Red Hat Enterprise Linux Server release 7."* && $(git --version) != "git version 2"*  ]]
    then
        printf "WARN: Installing additional repo to enable Git 2 on RHEL 7 hosts.\n"
        sudo yum -y remove git*
        sudo yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
    fi

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
        libffi-devel \
        libvirt \
        make \
        ncurses \
        openssl \
        openssl-devel \
        openssl11-libs \
        parallel \
        patch \
        podman \
        readline \
        readline-devel \
        sqlite \
        sqlite-devel \
        tk-devel \
        tree \
        unzip \
        xz-devel \
        zlib-devel
}

# NOTE: This should be moved into the above package manager once non-dnf host support has been removed.
# NOTES: This package (session-manager-plugin) is NOT needed for ECS hosted services nor AWS provided Amazon Linux EC2 hosts
function install_aws_session_manager_plugin() {
    printf "ALERT: We should try to add this tools to the Aqua Registry. We should try to limit the number of tools installed via scripting.\n"

    # TODO remove this once the node has been migrated to ECS Cluster hosting
    if [[ $(cat /etc/*release) = *"Red Hat"* ]]
    then
        printf "WARN: Another garbage work arounds for RHEL 7.x. on the bambora-aws Jenkins node.\n"
        export JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto/"
    fi

    # aws - ssm-session-manager plugin
    # https://stackoverflow.com/questions/12806176/checking-for-installed-packages-and-if-not-found-install
    printf "INFO: Processing AWS session-manager-plugin.\n"

    # >= 0.56.0 required
    if [[ -d "$HOME/.local/bin/session-manager-plugin" ]]
    then
        printf "WARN: Removing AWS session-manager-plugin from old location.\n"
        rm "$HOME/.local/bin/session-manager-plugin"
    fi

    # shellcheck disable=SC2126
    if [[ $(which dnf) && $(dnf list installed | cut -f1 -d" " | grep --extended "^session-manager-plugin*" | wc -l) == 0 ]]
    then
        echo "INFO: Installing AWS CLI session-manager-plugin via dnf system package manager.";
        # Fedora
        if [[ $(uname -m) == "x86_64" || $(uname -m) == "amd64" ]]
        then
            ## amd64
            # Use RPM to support `reinstall`
            sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
        elif [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
        then
            ## arm64
            # Use RPM to support `reinstall`
            sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_arm64/session-manager-plugin.rpm"
        else
            prinf "ALERT: Unable to determine CPU architecture for Fedora distro of AWS session-manager-plugin.\n"
        fi
    elif [[ $(which yum) && $(yum list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) == 0 ]]
    then
        # DEPRECATED 2024-03-11
        # remove on 2028-10-01
        # Use intstall_dnf()
        # RHEL
        echo "INFO: Installing AWS CLI session-manager-plugin via yum system package manager.";
        # We have to manually remove the symlink to make the pacakge install idempotent
        sudo rm "/usr/bin/session-manager-plugin" || true
        sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
    elif [[ $(which apt) && $(apt list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) == 0 ]]
    then
        # DEPRECATED 2024-03-11
        # remove on 2028-10-01
        # Use intstall_dnf()
        echo "INFO: Installing AWS CLI session-manager-plugin via apt system package manager.";
        if [[ $(uname -m) == "x86_64" || $(uname -m) == "amd64" ]]
        then
            ## arm64
            curl \
                --location \
                --output "session-manager-plugin.deb" \
                --show-error \
                "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb"
        elif [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
        then
            ## amd64
            curl \
                --location \
                --output "session-manager-plugin.deb" \
                --show-error \
                "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb"
        else
            prinf "ALERT: Unable to determine CPU architecture for Debian distro of AWS session-manager-plugin.\n"
        fi
        sudo dpkg -i session-manager-plugin.deb
    fi
}

# logic

printf "INFO: Installing system tool using OS package manager.\n"
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
    printf "WARN: No supported system package manager found. Please consider submitting an update adding your distributions package manager.\n"
    exit 1
fi

install_aws_session_manager_plugin

# shellcheck disable=SC2088,SC2143
if [[ -f "${SESSION_SHELL}" && ! $(grep "export TF_PLUGIN_CACHE_DIR" "${SESSION_SHELL}")  ]]
then
    # source https://www.tailored.cloud/devops/cache-terraform-providers/
    printf "INFO: Configuring Terraform provider shared cache.\n"
    mkdir -p ~/.terraform.d/plugin-cache/ || true
    echo "export TF_PLUGIN_CACHE_DIR=~/.terraform.d/plugin-cache/" >> "${SESSION_SHELL}"
fi
