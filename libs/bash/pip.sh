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
    # DO NOT INSTALL LocalStack on RHEL 7 machines
    if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
    then
        printf "WARN: NOT installing LocalStack on Red Hat hosts to unsupported host OS.\n"
        return 0
    fi

    # Check for valid user
    if [[ $(whoami) == "jenkins" || $(whoami) == "root" ]]
    then
        

        # Different install configuration depending on host type
        if [[ $(cat /etc/*release) == *"Cloud Edition"* || $(cat /etc/*release) == *"Workstation Edition"* ]]
        then
            printf "INFO: Install localstack on Cloud or Workstation host.\n"
            pip install --user localstack
        elif [[ $(cat /etc/*release) == *"Container Edition"* ]]
        then
            printf "INFO: Install localstack in Container host. This can take a LONG time.\n"
            pip install --user localstack[runtime]
        else
            printf "WARN: Unable to determine host type. Skipping Localstack install.\n"
        fi
    fi
}

function install_pip_packages() {
    {
        printf "INFO: Install Python modules via PIP package manager using requirements.txt\n"
        echo "export PATH=/home/david/.local/bin:$PATH" >> "${SESSION_SHELL}"

        python -m ensurepip --upgrade
        pip install --upgrade pip
        pip install --user --requirement requirements.txt
    } || {
        printf "ERR: Failed to install pip packages\n"
        exit 1
    }

    which pip
    pip --version
}

install_pip_packages
install_pip_localstack
