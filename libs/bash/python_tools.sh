#!/bin/false

# preflight

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# configuration

# functions

function install_python_tools_package_localstack() {
    # Check for valid user
    {
        if [[ $(whoami) == "jenkins" || $(whoami) == "root" ]]
        then
            # Different install configuration depending on host type
            if [[ $(cat /etc/*release) == *"Cloud Edition"* || $(cat /etc/*release) == *"Workstation Edition"* ]]
            then
                printf "INFO: Install localstack on Cloud or Workstation host.\n"
                pip install \
                    --prefix "$HOME/.local" \
                    localstack
            elif [[ $(cat /etc/*release) == *"Container Image"* ]]
            then
                printf "INFO: Install localstack in Container host. This can take a LONG time.\n"
                pip install \
                    --prefix "$HOME/.local" \
                    localstack[runtime]
                # pip install \
                #     --prefix "$HOME/.local" \
                #     --requirements ./libs/bash/localstack_runtime_requirements.txt \
            else
                printf "WARN: Unable to determine host type. Skipping localstack install.\n"
            fi
        fi
    } || {
        printf "ERR: Unable to install localstack.\n"
        exit 1
    }
}

function install_python_tools_packages() {
    {
        printf "INFO: Install Python modules via pip package manager using requirements.txt\n"
        append_add_path "$HOME_USER_BIN" "${SESSION_SHELL}"
        add_path "$HOME_USER_BIN"

        pip install \
            --prefer-binary \
            --prefix "$HOME/.local" \
            --requirement requirements.txt
    } || {
        printf "ERR: Failed to install pip packages\n"
        exit 1
    }
}

# logic

which pip
pip --version

install_python_tools_package_localstack
install_python_tools_packages

pip list --verbose
