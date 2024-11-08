#!/bin/false

# preflight

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# configuration

# functions

# This is needed until we are able to start, use, and destroy ephemeral instances of localstack per app/service/pipeline execution
function install_python_tools_package_localstack() {
    {
        # Only allow install of localstack[runtime] if doing so for automation
        # and only if in a container build context of a fedora base image
        if [[ ($(whoami) == "jenkins" || $(whoami) == "root") && $(cat /etc/*release) == *"Container Image"* ]]
        then
            printf "INFO: Install localstack in Container host. This can take a LONG time.\n"
            pip install \
                --prefer-binary \
                --prefix "$HOME/.local" \
                --requirement requirements_localstack_runtime.txt \
                localstack[runtime]
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
