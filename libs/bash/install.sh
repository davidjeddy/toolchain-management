#!/bin/bash -l

# preflight

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# configuration

declare OLD_PWD
OLD_PWD="$(pwd)"
printf "INFO: OLD_PWD: %s\n" "${OLD_PWD}"

if [[ ! $HOME || $HOME == "" ]]
then
    printf "ERR: HOME EN VAR must be set"
    exit 1
fi

if [[ "$EUID" -eq 0 && ! "${WL_GC_TOOLCHAIN_ROOT_OVERRIDE}" ]]
then
  echo "Do not run the install script as root."
  exit 1
fi

# Set value if empty
if [[ ! $WL_GC_TM_WORKSPACE ]]
then
    WL_GC_TM_WORKSPACE="$(pwd)"
    if [[ "$0" == *".tmp/toolchain-management"* ]]
    then
        # If this script is called from inside a path containing .tmp; we expect this project to be a upstream dependency
        # https://stackoverflow.com/questions/20572934/get-the-name-of-the-caller-script-in-bash-script
        WL_GC_TM_WORKSPACE="$(pwd)/.tmp/toolchain-management"
    fi
fi
export WL_GC_TM_WORKSPACE
printf "INFO: WL_GC_TM_WORKSPACE is %s\n" "${WL_GC_TM_WORKSPACE}"
cd "${WL_GC_TM_WORKSPACE}" || exit 1

source './libs/bash/common/utils.sh'

# Non-login shell - https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
declare SESSION_SHELL
SESSION_SHELL="${HOME}/.toolchainrc"
if [[ $- == *i* ]]
then
    SESSION_SHELL="$HOME/.toolchainrc"
fi
export SESSION_SHELL

# For use by java_tools and python_tools
declare HOME_USER_BIN
HOME_USER_BIN="${HOME}/.local/bin"
if [[ ! -d "$HOME_USER_BIN" ]]
then
    printf "INFO: %s does not exist, creating.\n" "$HOME_USER_BIN"
    mkdir -p "$HOME_USER_BIN"
fi
export HOME_USER_BIN
printf "INFO: HOME_USER_BIN is %s\n" "${HOME_USER_BIN}"

# functions

# logic

### system packages

if [[ ! "${WL_GC_TOOLCHAIN_SYSTEM_TOOLS_SKIP}" ]]
then
    source "./libs/bash/system_tools.sh" || exit 1
fi

### language packages

if [[ ! "${WL_GC_TOOLCHAIN_JAVA_TOOLS_SKIP}" ]]
then
    source "./libs/bash/java_tools.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_PYTHON_TOOLS_SKIP}" ]]
then
    source "./libs/bash/python_tools.sh" || exit 1
fi

### user packages

if [[ ! "${WL_GC_TOOLCHAIN_ASDF_SKIP}" ]]
then
    source "./libs/bash/asdf.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_ASDF_TOOLS_SKIP}" ]]
then
    source "./libs/bash/asdf_tools.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_IAC_TOOLS_SKIP}" ]]
then
    source "./libs/bash/iac_tools.sh" || exit 1
fi

# initialize environment

if ! [ -f "$HOME/.bashrc" ]
then
  touch "$HOME/.bashrc"
fi
append_if 'source ~/.toolchainrc' "$HOME/.bashrc"
printf 'You may want to source ~/.bashrc from ~/.bash_profile or ~/.bash_login\n'

# wrap up

# Return to original location
cd "$OLD_PWD" || exit 1

printf "INFO: Done. Please reload your shell session.\n"
