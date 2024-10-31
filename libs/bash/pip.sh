#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

function install_pip_packages() {
    {
        printf "INFO: Install Python modules via PIP package manager using requirements.txt\n"
        echo "export PATH=$HOME_USER_BIN:\$PATH" >> "${SESSION_SHELL}"

        python -m ensurepip --upgrade
        pip install --upgrade pip
        pip install --user --requirement requirements.txt
    } || {
        printf "ERR: Failed to install pip packages\n"
        exit 1
    }

    # localstack installs differently for bare metal VS container install
    # TODO deploy localstack as a stand alone service in the ECS cluster
    # pipeline -> launch localstack (stand alone) task w/ TTL of 1hr -> destroy on pipeline exit
    if [[ $(whoami) == "jenkins" || $(whoami) == "root" ]]
    then
        declare LS_VER
        LS_VER=""

        if [[ $(cat /etc/*release) == *"Container Edition"* ]]
        then
            printf "INFO: Install localstack in Container host. This can take a LONG time.\n"
            LS_VER="[runtime]"
        fi

        pip install --user localstack"$LS_VER"
    fi

    which pip
    pip --version
}

install_pip_packages
