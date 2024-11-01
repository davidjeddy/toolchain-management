#!/bin/bash -l

# preflight

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# configuration

# functions

function asdf_install() {
    printf "INFO: starting asdf_install().\n"

    if [[ ! $(which asdf) || $(asdf --version) != $(cat .asdf-version)* ]]
    then
        # Remove if exists
        if [[ -d "$HOME/.asdf" ]]
        then
            rm -rf "$HOME/.asdf"
        fi

        # clone new version
        git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch "$(cat .asdf-version)"
    fi

    if [[ $(cat "$SESSION_SHELL") != *".asdf/asdf.sh"* ]]
    then
        printf "INFO: asdf package manager is not in PATH, adding...\n"
        echo "source $HOME/.asdf/asdf.sh" >>  "${SESSION_SHELL}"
        echo "source $HOME/.asdf/completions/asdf.bash" >> "${SESSION_SHELL}"
        # shellcheck disable=SC1090
        source "${SESSION_SHELL}" || exit 1
    fi

    printf "INFO: Copy asdf-vm .tool-versions to user \$HOME to prevent \"No version is set ...\" error\n."
    cp .tool-versions "$HOME/.tool-versions" || exit 1

    which asdf
    asdf version
}

# logic

asdf_install
