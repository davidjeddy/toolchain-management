#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

function install_golang_via_goenv() {
    printf "INFO: install_golang_via_goenv()\n"
    printf "INFO: SESSION_SHELL: %s\n" "$SESSION_SHELL"
    printf "INFO: GOENV_VER: %s\n" "$GOENV_VER"
    printf "INFO: GO_VER: %s\n" "$(cat .go-version)"

    if [[ ! $(which goenv) ]]
    then
        printf "INFO: Installing goenv to %s to enable Go support\n" "$HOME/.goenv"
        rm -rf "$HOME/.goenv" || true
        git clone --quiet "https://github.com/go-nv/goenv.git" "$HOME/.goenv"

        # shellcheck disable=SC2143
        if [[ -f ${SESSION_SHELL} && ! $(grep "export GOENV_ROOT" "${SESSION_SHELL}") ]]
        then
            printf "INFO: Add goenv bin dir to PATH via %s.\n" "${SESSION_SHELL}"
            # shellcheck disable=SC2016
            {
                echo 'export GOENV_ROOT="$HOME/.goenv"'
                echo 'export PATH="$GOENV_ROOT/bin:$GOENV_ROOT/shims:$PATH"'
                echo 'eval "$(goenv init -)"'
            } >> "${SESSION_SHELL}"
        fi

        # shellcheck disable=SC1090
        source "${SESSION_SHELL}"

        {
            goenv install --force --quiet "$(cat .go-version)"
            goenv global "$(cat .go-version)"
        } || {
            printf "ERR: Failed to install Golang via goenv\n"
            exit 1
        }
    fi

    # If installed version does not match desired version
    if [[ $(which goenv) && $(go version) != *"$(cat .go-version)"* ]]
    then
        printf "INFO: Updating Golang via goenv to version %s\n" "$(cat .go-version)"

        declare OLD_PWD
        OLD_PWD="$(pwd)"
        cd "$HOME/.goenv" || exit 1

        git reset master --hard
        git fetch --all --tags
        git checkout "$GOENV_VER"

        cd "$OLD_PWD" || exit 1

        {
            goenv install --force --quiet "$(cat .go-version)"
            goenv global "$(cat .go-version)"
        } || {
            printf "ERR: Failed to update Golang via goenv\n"
            exit 1
        }
    fi

    # If no *env AND runtime interpreter is not found
    if [[ ! $(which goenv) || ! $(which go) || $(go version) != *"$(cat .go-version)"* ]]
    then
        printf "ERR: Failed to install Golang via goenv.\n"
        exit 1
    fi

    # -----

    which goenv
    goenv version
    which go
    go version
}

install_golang_via_goenv
