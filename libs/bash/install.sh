#!/usr/bin/env bash

set -e

# Example usage:
# Note `--skip_*_tools` and `--update` can be used together to update specific tool groups
# ./libs/bash/install.sh
# ./libs/bash/install.sh --platform darwin
# ./libs/bash/install.sh --platform darwin --update true
# ./libs/bash/install.sh --platform linux
# ./libs/bash/install.sh --platform linux --shell_profile ~/.zshell_profile
# ./libs/bash/install.sh --platform linux --skip_misc_tools true
# ./libs/bash/install.sh --bin_dir "/usr/bin" --skip_cloud_tools true --update true
# ./libs/bash/install.sh --skip_cloud_tools true --update true
# ./libs/bash/install.sh --skip_system_tools true --skip_iac_tools true --skip_misc_tools true

# On Apple M1/M2/ARM
# ./libs/bash/install.sh

## do NOT run script as root

if [ "$EUID" -eq 0 ]
then
  echo "Do not run the install script as root."
  exit 1
fi

# cli arg parsing

## Internal VARs
declare ARCH
declare ALT_ARCH
declare BIN_DIR
declare ORIG_PWD
declare PLATFORM
declare SHELL_PROFILE
declare SKIP_CLOUD_TOOLS
declare SKIP_MISC_TOOLS
declare SKIP_SYSTEM_TOOLS
declare SKIP_IAC_TOOLS
declare WL_GC_TM_WORKSPACE # Worldline - Global Collect - Toollchain Management - Workspace

## parse positional cli args
while [ $# -gt 0 ]; do
    if [[ $1 == "--help" ]]
    then
        printf "INFO: Open the script, check the header section for."
        exit 0
    elif [[ $1 == "--"* ]]
    then
        if [[ "$2" == "" ]]
        then
            printf "ERR: Argument '%s' has no value. Exiting with error.\n" "${1}"
            exit 1
        fi

        key="${1/--/}"
        declare "${key^^}"="$2"
        shift
    fi
    shift
done

# Argument Defaults

ARCH=$(uname -m)
if [[ $ARCH = *aarch64* && $ARCH = *x84_64* ]]
then
    printf "ERR: Unsupport process architecture detected from %s. Please submit a change request with the additions for your machine type." $(uname -m)
    # exit 1
fi

ALT_ARCH=""
if [[ $ARCH == "x86_64" ]]
then
    ALT_ARCH="amd64"
elif [[ $ARCH == "aarch64" ]]
then
    ALT_ARCH="arm64"
fi

if [[ "${BIN_DIR}" == "" ]]
then
    # https://unix.stackexchange.com/questions/8656/usr-bin-vs-usr-local-bin-on-linux
    # path for binaries NOT managed by a system packagemanager
    BIN_DIR="/usr/local/bin"
fi

ORIG_PWD="$(pwd)"

if [[ "$PLATFORM" == "" ]]
then
    PLATFORM="linux"
fi

if [[ "$(ps -o args= $PPID)" == *install.sh* ]]
then
    # If this script is called by another install.sh script; we expect this project to be inside the $(pwd)/.tmp dir
    # https://stackoverflow.com/questions/20572934/get-the-name-of-the-caller-script-in-bash-script
    WL_GC_TM_WORKSPACE="$(pwd)/.tmp/toolchain-management"
else
    WL_GC_TM_WORKSPACE="$(pwd)"
fi

if [[ "$SHELL_PROFILE" == "" ]]
then
    SHELL_PROFILE=~/.worldline_pps_profile
fi

if [[ "$UPDATE" = "" ]]
then
    UPDATE="false"
fi

# to prevent sub-shells from duplicating outputs into $SHELL_PROFILE export all the values
export ALT_ARCH
export ARCH
export BIN_DIR
export ORIG_PWD
export PLATFORM
export SHELL_PROFILE
export SKIP_CLOUD_TOOLS
export SKIP_IAC_TOOLS
export SKIP_MISC_TOOLS
export SKIP_SYSTEM_TOOLS
export UPDATE
export WL_GC_TM_WORKSPACE

## output runtime configuration
printf "INFO: Executing with the following argument configurations.\n"

echo "ALT_ARCH: $ALT_ARCH"
echo "ARCH: $ARCH"
echo "BIN_DIR: $BIN_DIR"
echo "ORIG_PWD: $ORIG_PWD"
echo "PLATFORM: $PLATFORM"
echo "SHELL_PROFILE: $SHELL_PROFILE"
echo "SKIP_CLOUD_TOOLS: $SKIP_CLOUD_TOOLS"
echo "SKIP_IAC_TOOLS: $SKIP_IAC_TOOLS"
echo "SKIP_MISC_TOOLS: $SKIP_MISC_TOOLS"
echo "SKIP_SYSTEM_TOOLS: $SKIP_SYSTEM_TOOLS"
echo "UPDATE: $UPDATE"
echo "WL_GC_TM_WORKSPACE: $WL_GC_TM_WORKSPACE"

## Execution

printf "INFO: Changing to Toolchain project root.\n"
cd "$WL_GC_TM_WORKSPACE" || exit 1

printf "INFO: Sourcing tool versions.sh in install.sh.\n"
# shellcheck disable=SC1091
source "$WL_GC_TM_WORKSPACE/libs/bash/versions.sh"

# Does $SHELL_PROFILE exist?
if [[ ! -f $SHELL_PROFILE || $UPDATE == "true" ]]
then 
    printf "INFO: Creating toolchain shell profile at %s\n" "$SHELL_PROFILE"
    rm -rf "$SHELL_PROFILE" || true
    touch "$SHELL_PROFILE" || exit 1

    printf "INFO: Add BIN_DIR to PATH via in %s.\n" "$SHELL_PROFILE"
    echo "export PATH=\$PATH:$BIN_DIR" >> "$SHELL_PROFILE"
    echo "export PATH=\$PATH:$WL_GC_TM_WORKSPACE/libs/bash" >> "$SHELL_PROFILE"
fi

# https://linuxize.com/post/bashrc-vs-bash-profile/
# Other tribes can add additional shell profiles as ~/[[business_unit]]_[[tribe]]_profile

# Add tribe profile to ~/.bash_profile for interactive shells
# shellcheck disable=SC2143
if [[ -f ~/.bash_profile && ! $(grep "source $SHELL_PROFILE" ~/.bash_profile) ]]
then
    printf "INFO: Adding source %s to %s.\n" "$SHELL_PROFILE" ~/.bash_profile
    echo "source $SHELL_PROFILE" >> ~/.bash_profile
    # shellcheck source=/home/jenkins/
    #shellcheck disable=SC1091
    source ~/.bash_profile || exit 1
fi

# Add tribe profile to ~/.bashrc for non-interactive shells
# shellcheck disable=SC2143
if [[ -f ~/.bashrc && ! $(grep "source $SHELL_PROFILE" ~/.bashrc) ]]
then
    printf "INFO: Adding source %s to %s.\n" "$SHELL_PROFILE" ~/.bashrc
    echo "source $SHELL_PROFILE" >> ~/.bashrc
    # shellcheck source=/home/jenkins/
    #shellcheck disable=SC1091
    source ~/.bashrc || exit 1
fi

printf "INFO: PATH value is: %s\n" "$PATH"

# System tools MUST be first
if [[ $SKIP_SYSTEM_TOOLS == "" ]]
then
    cd "$WL_GC_TM_WORKSPACE" || exit 1
    # shellcheck disable=SC1091
    source "${WL_GC_TM_WORKSPACE}/libs/bash/system_tools.sh"
    install_system_tools
fi

# Additional tool management sorted alphabetically
if [[ $SKIP_CLOUD_TOOLS == "" ]]
then
    cd "$WL_GC_TM_WORKSPACE" || exit 1
    # shellcheck disable=SC1091
    source "${WL_GC_TM_WORKSPACE}/libs/bash/cloud_tools.sh"
    install_cloud_tools
fi

if [[ $SKIP_MISC_TOOLS == "" ]]
then
    cd "$WL_GC_TM_WORKSPACE" || exit 1
    # shellcheck disable=SC1091
    source "${WL_GC_TM_WORKSPACE}/libs/bash/misc_tools.sh"
    install_misc_tools
fi

if [[ $SKIP_IAC_TOOLS == "" ]]
then
    cd "$WL_GC_TM_WORKSPACE" || exit 1
    # shellcheck disable=SC1091
    source "${WL_GC_TM_WORKSPACE}/libs/bash/iac_tools.sh"
    install_iac_tools
fi

# Post-processing checkups

printf "INFO: Changing back to original working dir.\n"
cd "$ORIG_PWD" || exit 1

if [[ ! -f ~/.aws/credentials && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.aws/credentials configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n"
fi

if [[ ! -f ~/.terraformrc && $(whoami) != 'jenkins' ]]
then
    printf "INFO: Looks like you do not yet have a ~/.terraformrc credentials configuration, pleaes follow https://confluence.techno.ingenico.com/display/PPS/Using+Shared+Modules+from+GitLab+Private+Registry#UsingSharedModulesfromGitLabPrivateRegistry-localhost before attempting to use Terraf.\n"
fi

# shellcheck disable=SC1091,SC1090
source "$SHELL_PROFILE"

# Done
printf "INFO: Please start your shell session to ensure the PATH value is reloaded.\n"

printf "INFO: ...Done.\n"
