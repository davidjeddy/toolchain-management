#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
# source "$SESSION_SHELL" || exit 1 # this is set from the logic below, unable to use it here. Lines here for consistancy

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# pre-lfight

declare OLD_PWD
OLD_PWD="$(pwd)"
printf "INFO: OLD_PWD: %s\n" "${OLD_PWD}"

## Preflight checks

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

# load ENV configuration

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

# logic

# First, determinr runtime VARS

# Set value if empty
if [[ ! $WL_GC_TM_WORKSPACE ]]
then
    WL_GC_TM_WORKSPACE=$(git rev-parse --show-toplevel)
    if [[ "$(ps -o args= $PPID)" == *".tmp"* ]]
    then
        # If this script is called from inside a path containing .tmp; we expect this project to be a upstream dependency
        # https://stackoverflow.com/questions/20572934/get-the-name-of-the-caller-script-in-bash-script
        WL_GC_TM_WORKSPACE="$(pwd)/.tmp/toolchain-management"
    else
        WL_GC_TM_WORKSPACE="$(pwd)"
    fi
fi
export WL_GC_TM_WORKSPACE
printf "INFO: WL_GC_TM_WORKSPACE is %s\n" "${WL_GC_TM_WORKSPACE}"
cd "${WL_GC_TM_WORKSPACE}" || exit 1

# Non-login shell - https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
declare SESSION_SHELL
SESSION_SHELL="${HOME}/.bashrc"
if [[ $- == *i* ]]
then
    SESSION_SHELL="$HOME/.bashrc"
fi
export SESSION_SHELL

# Remove configurations from start line to end line (inclusive)
# While this removes only one instance per run, eventually the empty blocks will all be removed
## < 0.55.0 strings
sed -i '/# WL GC Toolchain Management Starting/,/# WL GC Toolchain Management Ending/d' "$HOME/.bashrc"
## > 0.55.0 strings
sed -i '/# WL - GC - Centaurus - Toolchain Management Starting/,/# WL - GC - Centaurus - Toolchain Management Ending/d' "$HOME/.bashrc"

# Put an indicator of where the toolchain configurations start
echo "# WL - GC - Centaurus - Toolchain Management Starting" >> "$SESSION_SHELL"

# shellcheck disable=SC1090,SC1091
source "${SESSION_SHELL}" || exit 1
printf "INFO: PATH is %s\n" "$PATH"

# Second, install tools and language interpreters not yet in aqua's standard registry

# shellcheck disable=SC1090,SC1091
source "./versions.sh" || exit 1

# tool sectinos

if [[ ! "${WL_GC_TOOLCHAIN_SYSTEM_TOOLS_SKIP}" ]]
then
    # shellcheck disable=SC1090,SC1091
    source "./libs/bash/system_tools.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_GOLANG_SKIP}" ]]
then
    # shellcheck disable=SC1090,SC1091
    source "./libs/bash/golang.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_JAVA_TOOLS_SKIP}" ]]
then
    # shellcheck disable=SC1090,SC1091
    source "./libs/bash/java_tools.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_PYTHON_SKIP}" ]]
then
    # shellcheck disable=SC1090,SC1091
    source "./libs/bash/python.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_PIP_SKIP}" ]]
then
    # shellcheck disable=SC1090,SC1091
    source "./libs/bash/pip.sh" || exit 1
fi

if [[ ! "${WL_GC_TOOLCHAIN_AQUA_SKIP}" ]]
then
    printf "INFO: Install Aqua tool management\n"
    # https://aquaproj.github.io/docs/products/aqua-installer#shell-script
    export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"
    curl -sSfL -O https://raw.githubusercontent.com/aquaproj/aqua-installer/v3.0.1/aqua-installer
    echo "fb4b3b7d026e5aba1fc478c268e8fbd653e01404c8a8c6284fdba88ae62eda6a  aqua-installer" | sha256sum -c

    chmod +x aqua-installer
    ./aqua-installer
fi

if [[ ! "${WL_GC_TOOLCHAIN_AQUA_TOOLS_SKIP}" ]]
then
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
    printf "INFO: PATH is %s\n" "$PATH"

    # Global baseline tool versions - always reset on every run
    # https://aquaproj.github.io/docs/reference/config/#configuration-file-path
    rm -rf ~/.aqua || true
    mkdir -p ~/.aqua
    # shellcheck disable=SC2088
    cp -rf "${WL_GC_TM_WORKSPACE}/aqua.yaml" ~/.aqua/aqua.yaml || exit 1

    which aqua
    aqua --version
    aqua update-checksum
    aqua install
fi

if [[ ! "${WL_GC_TOOLCHAIN_IAC_SKIP}" ]]
then
    printf "INFO: Setting CLI *env tool versions.\n"

    # shellcheck disable=SC2046
    tfenv install "$(cat .terraform-version)"

    # shellcheck disable=SC2046
    tfenv use "$(cat .terraform-version)"

    # shellcheck disable=SC2046
    tgenv install "$(cat .terragrunt-version)"

    mkdir -p "$HOME/.local/share/aquaproj-aqua/pkgs/github_archive/github.com/tgenv/tgenv/v$(cat .terragrunt-version)/tgenv-$(cat .terragrunt-version)" || exit 1
    cat .terragrunt-version > "$HOME/.local/share/aquaproj-aqua/pkgs/github_archive/github.com/tgenv/tgenv/v$(cat .terragrunt-version)/tgenv-$(cat .terragrunt-version)/version"
    tgenv use "$(cat .terragrunt-version)"

    # shellcheck disable=SC2046
    tofuenv install "$(cat .tofu-version)"

    # shellcheck disable=SC2046
    tofuenv use "$(cat .tofu-version)"

    # shellcheck disable=SC1090,SC1091
    source "./libs/bash/iac_tools.sh" || exit 1
fi

# wrap up

# credentials configuration
if [[ ! -f ~/.aws/credentials && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.aws/credentials configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n"
fi

if [[ ! -f ~/.terraformrc && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.terraformrc credentials configuration, please follow https://confluence.worldline-solutions.com/display/PPSTECHNO/Using+Shared+Modules+from+GitLab+Private+Registry before attempting to use Terraform or OpenTofu.\n"
fi

# Third, use *env tools to per-directory IAC tool default versions

printf "INFO: Setting CLI *env tool versions.\n"

# shellcheck disable=SC2046
tfenv install "$(cat .terraform-version)"

# shellcheck disable=SC2046
tfenv use "$(cat .terraform-version)"

# shellcheck disable=SC2046
tgenv install "$(cat .terragrunt-version)"

mkdir -p "$HOME/.local/share/aquaproj-aqua/pkgs/github_archive/github.com/tgenv/tgenv/v$(cat .terragrunt-version)/tgenv-$(cat .terragrunt-version)" || exit 1
cat .terragrunt-version > "$HOME/.local/share/aquaproj-aqua/pkgs/github_archive/github.com/tgenv/tgenv/v$(cat .terragrunt-version)/tgenv-$(cat .terragrunt-version)/version"
tgenv use "$(cat .terragrunt-version)"

# shellcheck disable=SC2046
tofuenv install "$(cat .tofu-version)"

# shellcheck disable=SC2046
tofuenv use "$(cat .tofu-version)"

# Put an indicator of where the toolchain configurations end
echo "# WL - GC - Centaurus - Toolchain Management Ending" >> "$SESSION_SHELL"

# Return to origina location
cd "$OLD_PWD" || exit 1

if [[ ! -f ~/.aws/credentials && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.aws/credentials configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n"
fi

if [[ ! -f ~/.terraformrc && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.terraformrc credentials configuration, pleaes follow https://confluence.worldline-solutions.com/display/PPSTECHNO/Using+Shared+Modules+from+GitLab+Private+Registry before attempting to use Terraf.\n"
fi

printf "INFO: Done. Please reload your shell by running the following command: \"source %s\".\n" "$SESSION_SHELL"
