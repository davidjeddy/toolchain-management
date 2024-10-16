#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

function install_pip_localstack() {

    {
        # Different install configuration depending on host type
        if [[ $(cat /etc/*release) == *"Cloud Edition"* || $(cat /etc/*release) == *"Workstation Edition"* ]]
        then
            printf "INFO: Install localstack on Cloud or Workstation host.\n"
            pip install \
            --prefix "$HOME/.local" \
            localstack
        elif [[ $(cat /etc/*release) == *"Container Edition"* ]]
        then
            printf "INFO: Install localstack in Container host. This can take a LONG time.\n"
            pip install \
            --prefix "$HOME/.local" \
            localstack[runtime]
        fi
    } || {
        printf "WARN: Unable to determine host type. Skipping Localstack install.\n"
        exit 1
    }
}

function install_pip_packages() {
    {
        printf "INFO: Install Python modules via PIP package manager using requirements.txt\n"
        echo "export PATH=$HOME_USER_BIN:$PATH" >> "${SESSION_SHELL}"

        python -m ensurepip --upgrade
        pip install --upgrade pip

        # As a safety, remove all packages first
        pip uninstall --yes --requirement requirements.txt

        # Because pip is not forth coming on where it installs the binaries, we will set it explicitly
        # https://stackoverflow.com/questions/49492344/pip-install-location
        pip install \
            --prefer-binary \
            --prefix "$HOME/.local" \
            --requirement requirements.txt
    } || {
        printf "ERR: Failed to install pip packages\n"
        exit 1
    }

    which pip
    pip --version
    pip list --verbose
}

install_pip_packages

# /etc/os-release file exists
# AND DO NOT INSTALL LocalStack on RHEL 7 machines
# AND Check for automation or container build users
if [[ -f "/etc/os-release" \
    &&  $(cat /etc/os-release) != *"Red Hat Enterprise Linux Server 7"* \
    && ($(whoami) == "jenkins" || $(whoami) == "root") ]]
then
    install_pip_localstack
fi

