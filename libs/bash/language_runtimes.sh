#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

function process_goenv() {
    printf "INFO: process_goenv()\n"
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

function process_pyenv() {
    printf "INFO: process_pyenv()\n"
    printf "INFO: SESSION_SHELL: %s\n" "$SESSION_SHELL"
    printf "INFO: PYENV_VER: %s\n" "$PYENV_VER"
    printf "INFO: PYTHON_VER: %s\n" "$(cat .python-version)"

    if [[ $(cat /etc/*release) != *"PRETTY_NAME=\"Fedora"* ]]
    then
        printf "WARN: Deprecated release of host OS detected. Do special things to make compiling Python > 3.x work.\n"
        export CFLAGS="$CFLAGS $(pkg-config --cflags openssl11)"
        export LDFLAGS="$LDFLAGS $(pkg-config --libs openssl11)"
    fi

    if [[ ! $(which pyenv) ]]
    then
        printf "INFO: Installing pyenv to %s to enable Python support\n" "$HOME/.pyenv"
        rm -rf "$HOME/.pyenv" || true

        # because pyenv installer does not provider checksum validation we use a locally stored and managed copy
        ./libs/bash/assets/pyenv.sh || exit 1

        # shellcheck disable=SC2143
        if [[ -f ${SESSION_SHELL} && ! $(grep "export PYENV_ROOT" "${SESSION_SHELL}") ]]
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
            python -m ensurepip --upgrade
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
            python -m ensurepip --upgrade
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

    which pip
    pip --version
    which python
    python --version
    which pyenv
    pyenv --version
}

function process_pip_install() {
    {
        printf "INFO: Install Python modules via PIP package manager using requirements.txt\n"
        pip install --upgrade pip
        pip install --user --requirement requirements.txt

        # DO NOT INSTALL LocalStack on RHEL 7 machines
        if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
        then
            printf "WARN: NOT installing LocalStack on Red Hat hosts to unsupported host OS.\n"
            return 0
        fi

        # ONLY install LocalStack[runtime] if the user is jenkins or root
        if [[ $(whoami) == "root" || $(whoami) == "jenkins" ]]
        then
            printf "INFO: Ensure localstack runs on all container / local hosts. This can take a long time during first run.\n"
            pip install --user localstack[runtime]
        fi

        {
            echo 'export PATH=/home/david/.local/bin:$PATH'
        } >> "${SESSION_SHELL}"
    } || {
        printf "ERR: Failed to install pip packages\n"
        exit 1
    }
}

process_goenv
process_pyenv
process_pip_install
