#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# functions

function asdf_install() {
    printf "INFO: starting asdf_install().\n"

    if [[ ! $(which asdf) || $(cat .asdf-version) != *$(asdf --version)* ]]
    then
        # Remove if exists
        rm -rf "$HOME/.asdf" || true
        rm "$HOME/.tool-versions" || true
        sudo rm "/usr/bin/asdf" || true

        # clone new version
        git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch "v$(cat .asdf-version)"
    fi

    if [[ ! $(which asdf) ]]
    then
        printf "INFO: asdf version manager is not in PATH, adding...\n"
        append_add_path "$HOME/.asdf/bin" "$SESSION_SHELL"
    fi

    append_add_path "$HOME/.asdf/shims" "$SESSION_SHELL"

    which asdf
    asdf version
}

# Install asdf >= 0.16.0
function asdf_install_gtoet_0_16_0() {
    printf "INFO: starting asdf_install_gtoet_0_16_0().\n"

    if [[ ! $(which asdf) || $(cat .asdf-version) != *$(asdf --version)* ]]
    then
        # Remove if exists to clear the installed plugins and related resources
        if [[ -d "$HOME/.asdf" ]]
        then
            rm -rf "$HOME/.asdf"
        fi

        # dra can pull release packages from GitHub w/o bespoke curl+tar+install complexity
        # Typical usage to install asdf-vm and IAC tools not available via asdf-vm but ARE hosted on GitHub
        if [[ ! $(which dra) ]]
        then
            # shellcheck disable=SC1091
            source "./libs/bash/dra_install.sh" || exit 1
            dra_install
        fi

        printf "INFO: Copy asdf-vm .tool-versions to user \$HOME to prevent \"No version is set ...\" error.\n"
        if [[ $(pwd) != "$HOME" ]]
        then
            cp -rf .tool-versions "$HOME/.tool-versions" || exit 1
        fi

        dra download --automatic --install --tag "v$(cat "${WL_GC_TM_WORKSPACE}"/.asdf-version)" asdf-vm/asdf
        sudo install -D -m 755 ./asdf /usr/local/bin
        rm ./asdf*
    fi

    which asdf
    asdf version
}
