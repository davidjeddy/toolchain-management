#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

function asdf_tools_install() {
    printf "INFO: starting asdf_tools_install()\n"

    # be sure we have some tools configured to even use asdf
    if [[ ! -s .tool-versions ]]
    then
        printf "WARN: No tools defined in asdf-vm .tool-versions, skipping.\n"
        return 0
    fi

    # required dependency for checkov as managed by asdf
    if [[ ! $(which python) || ! $(which pip) ]]
    then
        printf "WARN: Python or PIP not detected, but is required, installing...\n"
        sudo dnf update --assumeyes
        sudo dnf install --assumeyes \
            python3-"$(cat .python-version)" \
            python3-pip
        sudo dnf reinstall --assumeyes python3-pip # I do not know why we have to do this but if we do not then pip is not found on the $PATH.
    fi

    # Add plugins not listed in https://github.com/asdf-vm/asdf-plugins if missing
    asdf plugin add sonarscanner https://github.com/virtualstaticvoid/asdf-sonarscanner.git || true

    # we do need to add each if missing
    cut -d' ' -f1 .tool-versions | xargs -I{} asdf plugin add {} || true

    # To be sure all tools, including additional plugin tools, are available to asdf globally
    printf "INFO: Copy asdf-vm .tool-versions to user \$HOME to prevent \"No version is set ...\" error\n."
    cp -rf ".tool-versions" "$HOME/.tool-versions" || exit 1

    # Install packages
    asdf install

    # Just to be sure
    asdf reshim

    # output package list
    asdf list
}
