#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

function install_python_via_pyenv() {
    printf "INFO: install_python_via_pyenv()\n"
    printf "INFO: SESSION_SHELL: %s\n" "$SESSION_SHELL"
    printf "INFO: PYENV_VER: %s\n" "$PYENV_VER"
    printf "INFO: PYTHON_VER: %s\n" "$(cat .python-version)"

    if [[ $(cat /etc/*release) != *"PRETTY_NAME=\"Fedora"* ]]
    then
        printf "WARN: Deprecated release of host OS detected. Do special things to make compiling Python > 3.x work.\n"
        declare CFLAGS
        CFLAGS="$CFLAGS $(pkg-config --cflags openssl11)"
        export CFLAGS
        declare LDFLAGS
        LDFLAGS="$LDFLAGS $(pkg-config --libs openssl11)"
        export LDFLAGS
    fi

    if [[ ! $(which pyenv) ]]
    then
        printf "INFO: Installing pyenv to %s to enable Python support\n" "$HOME/.pyenv"
        rm -rf "$HOME/.pyenv" || true

        # because pyenv installer does not provider checksum validation we use a locally stored and managed copy
        ./libs/bash/assets/pyenv.sh || exit 1

        # shellcheck disable=SC2143
        if [[ ! $(grep "export PYENV_ROOT" "${SESSION_SHELL}") ]]
        then
            printf "INFO: Add pyenv bin dir to PATH via %s.\n" "${SESSION_SHELL}"
            # shellcheck disable=SC2016
            {
                echo 'export PYENV_ROOT="$HOME/.pyenv"'
                echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
                echo 'export PATH="$PYENV_ROOT/shims:$PATH"'
                echo 'command -v pyenv > /dev/null'
                echo 'eval "$(pyenv init -)"'
                echo 'eval "$(pyenv virtualenv-init -)"'
            } >> "${SESSION_SHELL}"

            # shellcheck disable=SC1090
            source "${SESSION_SHELL}"
        fi

        {
            pyenv install --force --verbose "$(cat .python-version)"
            pyenv global "$(cat .python-version)"
        } || {
            printf "ERR: Failed to install Python via pyenv\n"
            exit 1
        }
    fi

    # If installed version does not match desired version
    if [[ $(which pyenv) && $(python --version) != *"$(cat .python-version)"* ]]
    then
        printf "INFO: Updating pyenv and Python to version %s\n" "$(cat .python-version)"
        pyenv update

        {
            pyenv install --force  --verbose "$(cat .python-version)"
            pyenv global "$(cat .python-version)"
        } || {
            printf "ERR: Failed to update Python via pyenv\n"
            exit 1
        }
    fi

    # If no *env AND runtime interpreter is not found
    if [[ ! $(which pyenv) || ! $(which python) || $(python --version) != *"$(cat .python-version)"* ]]
    then
        printf "ERR: Failed to install Python via pyenv.\n"
        exit 1
    fi

    # -----

    which python
    python --version
    which pyenv
    pyenv --version
}

install_python_via_pyenv
