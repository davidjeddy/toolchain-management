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

    if [[ ! -s .tool-versions ]]
    then
        printf "WARN: No tools defined in asdf-vm .tool-versions, skipping.\n"
        return 0
    fi

    # Since we use this CLI invocation we can not (currently) have comments in the source file so here is what we would have
    # https://asdf-vm.com/manage/configuration.html
    # Provided by well-known plugin short list
    # https://github.com/asdf-vm/asdf-plugins
    # Added via local `plugin add`
    # https://asdf-vm.com/manage/configuration.html
    # https://github.com/asdf-vm/asdf/issues/276
    if [[ $(asdf plugin list installed) != "*" ]]
    then
        printf "INFO: Removing existing asdf-vm plugins.\n"
        {
            asdf plugin list installed | xargs -I{} asdf plugin remove {}
        } || {
            printf "WARN: Unable to clear asdf-vm plugin list, skipping.\n"
        }
    fi

    # List installed plugins
    asdf plugin list
    # Add plugins from configuration
    cut -d' ' -f1 .tool-versions | xargs -I{} asdf plugin add {}

    # checkov requires Python
    if [[ ! $(which python) || ! $(which pip) ]]
    then
        printf "WARN: Python or PIP not detected, but is required, installing...\n"
        sudo dnf update --assumeyes
        sudo dnf install --assumeyes "python3-$(cat .python-version)" python3-pip
    fi

    # Install packages
    asdf install

    # Add plugins not listed in https://github.com/asdf-vm/asdf-plugins
    asdf plugin-add sonarscanner https://github.com/virtualstaticvoid/asdf-sonarscanner.git
    asdf install sonarscanner "$(cat .sonarscanner-version)"

    # Just to be sure
    asdf reshim

    # output package list
    asdf list
}
