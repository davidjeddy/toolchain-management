#!/usr/bin/env bash

set -e

## do NOT run script as root

if [ "$EUID" -eq 0 ]
then
  echo "Do not run the install script as root."
  exit 1
fi

## 

# Non-login shell - https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
declare SESSION_SHELL
SESSION_SHELL="${HOME}/.bashrc"
if [[ $- == *i* ]]
then
    SESSION_SHELL=~/.bashrc
fi
printf "INFO: SESSION_SHELL is %s\n" "${SESSION_SHELL}"

# shellcheck disable=SC1090,SC1091
source "${SESSION_SHELL}" || exit 1
printf "INFO: PATH is %s\n" "$PATH"

# shellcheck disable=SC2088,SC2143
if [[ -f "${SESSION_SHELL}" && ! $(grep "export TF_PLUGIN_CACHE_DIR" "${SESSION_SHELL}")  ]]
then
    # source https://www.tailored.cloud/devops/cache-terraform-providers/
    printf "INFO: Configuring Terraform provider shared cache.\n"
    mkdir -p ~/.terraform.d/plugin-cache/ || true
    echo "export TF_PLUGIN_CACHE_DIR=~/.terraform.d/plugin-cache/" >> "${SESSION_SHELL}"
fi

# Now for tools not yet in aqua's standard registry
# shellcheck disable=SC1090,SC1091
source "versions.sh" || exit 1

# shellcheck disable=SC1090,SC1091
source "./libs/bash/system_tools.sh" || exit 1
install_system_tools

# shellcheck disable=SC1090,SC1091
source "./libs/bash/additional_tools.sh" || exit 1
additional_tools

# shellcheck disable=SC1090,SC1091
source "${SESSION_SHELL}" || exit 1
printf "INFO: PATH is %s\n" "$PATH"

if [[ ! $(which aqua) ||  $(aqua version) != *"aqua version $AQUA_VER"* ]]
then
    printf "INFO: Install Aqua\n"
    # https://aquaproj.github.io/docs/products/aqua-installer#shell-script
    curl -sSfL -O https://raw.githubusercontent.com/aquaproj/aqua-installer/v3.0.0/aqua-installer
    echo "8299de6c19a8ff6b2cc6ac69669cf9e12a96cece385658310aea4f4646a5496d  aqua-installer" | sha256sum -c
    chmod +x aqua-installer
    ./aqua-installer
fi

# shellcheck disable=SC2143
if [[ -f ${SESSION_SHELL} && ! $(grep "aquaproj-aqua" "${SESSION_SHELL}") ]]
then
    printf "INFO: Adding source %s to %s.\n" "$AQUA_ROOT_DIR" "${SESSION_SHELL}"
    echo "export PATH=${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin::q$PATH" >> "${SESSION_SHELL}"
fi

# shellcheck disable=SC1090,SC1091
source "${SESSION_SHELL}" || exit 1
printf "INFO: PATH is %s\n" "$PATH"

which aqua
aqua --version
aqua info

aqua init
aqua install

printf "INFO: CLI env tools install.\n"
tfenv install
tgenv install
tofuenv install

## Wrap up

if [[ ! -f ~/.aws/credentials && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.aws/credentials configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n"
fi

if [[ ! -f ~/.terraformrc && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.terraformrc credentials configuration, pleaes follow https://confluence.techno.ingenico.com/display/PPS/Using+Shared+Modules+from+GitLab+Private+Registry#UsingSharedModulesfromGitLabPrivateRegistry-localhost before attempting to use Terraf.\n"
fi

printf "INFO: Done. Please reload your shell be running \"source ~/.bashrc\".\n"
