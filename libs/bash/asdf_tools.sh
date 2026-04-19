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

    # Add plugins not listed in https://github.com/asdf-vm/asdf-plugins if missing
    asdf plugin add sonarscanner https://github.com/virtualstaticvoid/asdf-sonarscanner.git || true

    # we do need to add each if missing
    cut -d' ' -f1 .tool-versions | xargs -I{} asdf plugin add {} || true

    # To be sure all tools, including additional plugin tools, are available to asdf globally
    printf "INFO: Copy asdf-vm .tool-versions to user \$HOME to prevent \"No version is set ...\" error\n."
    cp -rf ".tool-versions" "$HOME/.tool-versions" || exit 1

    # Install packages
    # dunno how to debug the "failed to run install callback: exit status 1" error, even trace does not provide much info.
    # for now we bypass the error with a capture. Revisit this after the next asdf-vm udpate
    asdf install || true

    # Just to be sure
    asdf reshim

    # to be sureAdd asdf shim dir to PATH
    append_add_path "$HOME/.asdf/shims:$PATH" "$SESSION_SHELL"

    # output package list
    asdf list
}
