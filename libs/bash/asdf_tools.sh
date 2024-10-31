#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# pre-lfight

# logic

function asdf_tools_install() {
    # Since we use this CLI invocatin we can not (currently) have comments in the source file so here is what we would have
    # https://asdf-vm.com/manage/configuration.html
    # Provided by well-known plugin short list
    # https://github.com/asdf-vm/asdf-plugins
    # Added via local `plugin add`
    # https://asdf-vm.com/manage/configuration.html
    # https://github.com/asdf-vm/asdf/issues/276
    cut -d' ' -f1 ./.tool-versions | xargs -I{} asdf plugin add  {}
    asdf install
    asdf reshim
}

asdf_tools_install

asdf list
