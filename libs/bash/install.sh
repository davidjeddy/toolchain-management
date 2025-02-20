#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## configuration

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

# shellcheck disable=SC1091
source "${WL_GC_TM_WORKSPACE}/libs/bash/common/utils.sh" || exit 1

# Non-login shell - https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
declare SESSION_SHELL
SESSION_SHELL="${HOME}/.toolchainrc"
if [[ ! -f "$SESSION_SHELL" ]]
then 
    printf "INFO: Creating missing %s\n" "$SESSION_SHELL"
    touch "$SESSION_SHELL"
fi
printf "INFO: SESSION_SHELL is %s\n" "$SESSION_SHELL"
export SESSION_SHELL

# Just in case, for some reason, the bashrc does not yet exist
if [[ ! -f "$HOME/.bashrc" ]]
then
  touch "$HOME/.bashrc"
fi

# This MUST be the "$HOME/.bashrc". This is the link between our tooling and the OS shell configuration.
append_if "source $SESSION_SHELL" "$HOME/.bashrc"
# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

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

## functions

## logic

### system packages

if [[ ! "${WL_GC_TOOLCHAIN_SYSTEM_TOOLS_SKIP}" ]]
then
    # shellcheck disable=SC1091
    source "./libs/bash/system_tools.sh" || exit 1
    dnf_systems
fi

### user packages

if [[ ! "${WL_GC_TOOLCHAIN_ASDF_SKIP}" ]]
then
    # shellcheck disable=SC1091
    source "./libs/bash/asdf.sh" || exit 1
    asdf_install
fi

if [[ ! "${WL_GC_TOOLCHAIN_ASDF_TOOLS_SKIP}" ]]
then
    # shellcheck disable=SC1091
    source "./libs/bash/asdf_tools.sh" || exit 1
    asdf_tools_install
fi

if [[ ! "${WL_GC_TOOLCHAIN_CLOUD_TOOLS_SKIP}" ]]
then
    # shellcheck disable=SC1091
    source "./libs/bash/cloud_tools.sh" || exit 1
    install_additional_cloud_tools
fi

if [[ ! "${WL_GC_TOOLCHAIN_CONTAINER_TOOLS_SKIP}" ]]
then
    # shellcheck disable=SC1091
    source "./libs/bash/container_tools.sh" || exit 1
    install_additional_container_tools
fi

if [[ ! "${WL_GC_TOOLCHAIN_IAC_TOOLS_SKIP}" ]]
then
    # shellcheck disable=SC1091
    source "./libs/bash/iac_tools.sh" || exit 1
    install_additional_iac_tools
fi

# wrap up

# Return to original location
cd "$OLD_PWD" || exit 1

# Load up everything before exit outputs
# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

tail "$HOME/.bashrc"
cat "$SESSION_SHELL"

printf "INFO: Done. Restart your shell.\n"
