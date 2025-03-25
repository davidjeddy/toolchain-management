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
        append_if "source ~/.asdf/asdf.sh" "${SESSION_SHELL}"
        append_if "source ~/.asdf/completions/asdf.bash" "${SESSION_SHELL}"
        # shellcheck disable=SC1090
        source "${SESSION_SHELL}" || exit 1
    fi

    printf "INFO: Copy asdf-vm .tool-versions to user \$HOME to prevent \"No version is set ...\" error\n."
    cp -rf ".tool-versions" "$HOME/.tool-versions" || exit 1

    which asdf
    asdf version
}

# Install asdf 0.16.0 >= 0.16.0
function asdf_install_gtoet_0_16_0() {
    printf "INFO: starting asdf_install_gtoet_0_16_0().\n"

    if [[ ! $(which asdf) || $(asdf --version) != $(cat .asdf-version)* ]]
    then
        # Remove if exists to clear the installed plugins and related resources
        if [[ -d "$HOME/.asdf" ]]
        then
            rm -rf "$HOME/.asdf"
        fi

        printf "INFO: Copy asdf-vm .tool-versions to user \$HOME to prevent \"No version is set ...\" error\n."
        echo "" > "$HOME/.tool-versions" || exit 1

        # because vendors can not seem to settle on consistent ARCH values
        local ARCH
        ARCH="amd64"
        if [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
        then
            ARCH="arm64"
        fi

        # clone new version
        curl \
            --create-dirs \
            --location "https://github.com/asdf-vm/asdf/releases/download/v$(cat .asdf-version)/asdf-v$(cat .asdf-version)-linux-${ARCH}.tar.gz" \
            --output ".tmp/asdf-v$(cat .asdf-version)-linux-${ARCH}.tar.gz"
        tar -xvzf ".tmp/asdf-v$(cat .asdf-version)-linux-${ARCH}.tar.gz" -C ".tmp"
        curl \
            --create-dirs \
            --location "https://github.com/asdf-vm/asdf/releases/download/v$(cat .asdf-version)/asdf-v$(cat .asdf-version)-linux-${ARCH}.tar.gz.md5" \
            --output ".tmp/asdf-v$(cat .asdf-version)-linux-${ARCH}.tar.gz.md5"
        cat ".tmp/asdf-v$(cat .asdf-version)-linux-${ARCH}.tar.gz.md5"
        md5sum ".tmp/asdf" ".tmp/asdf-v$(cat .asdf-version)-linux-${ARCH}.tar.gz.md5"
        
        if [[ "$?" != "0" ]]
        then
            printf "ERR: asdf checksum does not match.\n"
            exit 1
        fi
    fi

    sudo install ".tmp/asdf" "/usr/bin"
    append_add_path "$ASDF_DATA_DIR/shims" "$SESSION_SHELL"

    which asdf
    asdf version
}