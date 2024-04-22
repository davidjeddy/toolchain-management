#!/usr/bin/env bash

# Example: ./libs/bash/install.sh
# Usage: ./libs/bash/install.sh

set -e

## Preflight checks

if [ "$EUID" -eq 0 ]
then
  echo "Do not run the install script as root."
  exit 1
fi

declare OLD_PWD
OLD_PWD="$(pwd)"
printf "INFO:OLD_PWD: %s\n" "%{OLD_PWD}"

## 

# First, determinr runtime VARS

WL_GC_TM_WORKSPACE=$(git rev-parse --show-toplevel)
if [[ "$(ps -o args= $PPID)" == *"install.sh"* ]]
then
    # If this script is called by another install.sh script; we expect this project to be inside the $(pwd)/.tmp dir
    # https://stackoverflow.com/questions/20572934/get-the-name-of-the-caller-script-in-bash-script
    WL_GC_TM_WORKSPACE="$(pwd)/.tmp/toolchain-management"
fi
export WL_GC_TM_WORKSPACE
printf "INFO: WL_GC_TM_WORKSPACE is %s\n" "${WL_GC_TM_WORKSPACE}"
cd "${WL_GC_TM_WORKSPACE}" || exit 1

# Non-login shell - https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
declare SESSION_SHELL
SESSION_SHELL="${HOME}/.bashrc"
if [[ $- == *i* ]]
then
    SESSION_SHELL=~/.bashrc
fi
export SESSION_SHELL
printf "INFO: SESSION_SHELL is %s\n" "${SESSION_SHELL}"

# Second, set IAC tool cache location

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

# Second, install tools and language interpreters not yet in aqua's standard registry

# shellcheck disable=SC1090,SC1091
source "./versions.sh" || exit 1

# shellcheck disable=SC1090,SC1091
source "./libs/bash/system_tools.sh" || exit 1

# shellcheck disable=SC1090,SC1091
source "./libs/bash/language_runtimes.sh" || exit 1

# shellcheck disable=SC1090,SC1091
source "./libs/bash/additional_tools.sh" || exit 1

# Third, now we can trigger Aqua to install all the other toolings

if [[ ! $(which aqua) ||  $(aqua version) != *"aqua version $AQUA_VER"* ]]
then
    printf "INFO: Install Aqua tool management\n"
    # https://aquaproj.github.io/docs/products/aqua-installer#shell-script
    curl --location --silent --show-error https://raw.githubusercontent.com/aquaproj/aqua-installer/v3.0.0/aqua-installer -o aqua-installer
    echo "8299de6c19a8ff6b2cc6ac69669cf9e12a96cece385658310aea4f4646a5496d  aqua-installer" | sha256sum -c
    chmod +x aqua-installer
    ./aqua-installer
fi

# shellcheck disable=SC2143
if [[ -f ${SESSION_SHELL} && ! $(grep "aquaproj-aqua" "${SESSION_SHELL}") ]]
then
    printf "INFO: Adding Aqua to PATH in %s.\n" "${SESSION_SHELL}"
    echo "export PATH=${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-~/.local/share}/aquaproj-aqua}/bin:$PATH" >> "${SESSION_SHELL}"
fi

# shellcheck disable=SC1090,SC1091
source "${SESSION_SHELL}" || exit 1

printf "INFO: PATH is %s\n" "$PATH"

# shellcheck disable=SC2143
if [[ -f ${SESSION_SHELL} && ! $(grep "AQUA_GLOBAL_CONFIG" "${SESSION_SHELL}") ]]
then
    printf "INFO: Setting global baseline aqua.yaml location in %s.\n" "${SESSION_SHELL}"
    echo "export AQUA_GLOBAL_CONFIG=~/.aqua/aqua.yaml" >> "${SESSION_SHELL}"
fi

# shellcheck disable=SC1090,SC1091
source "${SESSION_SHELL}" || exit 1

# shellcheck disable=SC1090,SC1091
printf "INFO: AQUA_GLOBAL_CONFIG is %s\n" "$AQUA_GLOBAL_CONFIG"

# Global baseline tool versions - always reset on every run
# https://aquaproj.github.io/docs/reference/config/#configuration-file-path
rm -rf ~/.aqua || true
mkdir -p ~/.aqua
# shellcheck disable=SC2088
cp -rf "${WL_GC_TM_WORKSPACE}/aqua.yaml" ~/.aqua/aqua.yaml || exit 1

which aqua
aqua --version

aqua info
aqua init
aqua install

printf "INFO: Setting CLI *env tool versions.\n"
# shellcheck disable=SC2046
tfenv install "$(cat .terraform-version)"
# shellcheck disable=SC2046
tfenv use "$(cat .terraform-version)"
# shellcheck disable=SC2046
tgenv install "$(cat .terragrunt-version)"
# shellcheck disable=SC2046
tgenv use "$(cat .terragrunt-version)"
# TODO Fix 'causes tgenv is not writing the default terragrunt version to file correctly
# shellcheck disable=SC2005
echo "$(cat .terragrunt-version)" > ~/.local/share/aquaproj-aqua/pkgs/github_archive/github.com/tgenv/tgenv/v1.2.0/tgenv-1.2.0/version
# shellcheck disable=SC2046
tofuenv install "$(cat .tofu-version)"
# shellcheck disable=SC2046
tofuenv use "$(cat .tofu-version)"

# Lastly, Wrap up and exit

cd "$OLD_PWD" || exit 1

if [[ ! -f ~/.aws/credentials && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.aws/credentials configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n"
fi

if [[ ! -f ~/.terraformrc && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.terraformrc credentials configuration, pleaes follow https://confluence.techno.ingenico.com/display/PPS/Using+Shared+Modules+from+GitLab+Private+Registry#UsingSharedModulesfromGitLabPrivateRegistry-localhost before attempting to use Terraf.\n"
fi

printf "INFO: Done. Please reload your shell by running the following command: \"source ~/.bashrc\".\n"
