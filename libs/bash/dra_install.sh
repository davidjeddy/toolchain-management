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

# Dra is a command line tool to download release assets from GitHub
# It is able to automatically detects CPU arch and untar/unzip release artifact
# https://github.com/devmatteini/dra
function dra_install() {
    printf "INFO: starting dra_install().\n"

    if [[ ! $(which dra) || $(cat .dra-version) != *$(dra --version)* ]]
    then
        curl \
            --proto '=https' \
            --tlsv1.2 \
            -sSf \
            https://raw.githubusercontent.com/devmatteini/dra/refs/heads/main/install.sh \
        | bash -s -- --to .
        sudo install -D -m 755 ./dra /usr/local/bin
        rm ./dra
    fi

    which dra
    dra --version
}
