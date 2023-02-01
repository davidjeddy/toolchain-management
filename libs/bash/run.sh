#!/bin/bash -e

# usage install.sh PLATFORM ARCH
# example install.sh
# example install.sh linux arm32
# example install.sh darwin amd64
# example export SKIP_SYSTEM_TOOL_INSTALL=true; install.sh

# pre-flight checks

if [[ ! -d .git ]]
then
    printf "ERROR: Please execute the installation from the root of the project using the command ./libs/install.sh"
    exit 1
fi

# cli arg parsing

## CLI args
declare arch
declare platform
declare shellrc
declare update

## Internal VARs
declare ARCH
declare PLATFORM
declare SHELLRC
declare PROJECT_ROOT

# shellcheck disable=SC2034
PROJECT_ROOT="$(pwd)"

## parse positional args
while [ $# -gt 0 ]; do
    if [[ $1 == "--help" ]]
    then
        echo "INFO: Open the script, check the examples section."
        exit 0
    elif [[ $1 == "--"* ]]
    then
        key="${1/--/}"
        declare "${key^^}"="$2"
        shift
    fi
    shift
done

# Argument defaults

if [[ "${ARCH}" == "" ]]
then
    ARCH="amd64"
fi

if [[ "${PLATFORM}" == "" ]]
then
    PLATFORM="linux"
fi

if [[ "${SHELLRC}" = "" ]]
then
    SHELLRC=".bashrc"
fi

if [[ "${UPDATE}" = "" ]]
then
    UPDATE="false"
fi

echo "ARCH: ${ARCH}"
echo "PLATFORM: ${PLATFORM}"
echo "SHELLRC: ${SHELLRC}"
echo "UPDATE: ${UPDATE}"

# # Tmp dir to download archives and unpack

# printf "INFO: Switching to %s/.tmp.\n" "${PROJECT_ROOT}"
# cd "${PROJECT_ROOT}" || exit
# sudo rm -rf .tmp || true
# mkdir -p .tmp
# cd .tmp || exit

# # install tools

# # System tools MUST be first
# if [[ $SKIP_SYSTEM_TOOL_INSTALL == "" ]]
# then
#     # shellcheck disable=SC1091
#     . "$PROJECT_ROOT/libs/system-tools.sh"
#     install_systm_tools
# fi

# # The rest are alphabeticl desc sorted
# if [[ $SKIP_AWS_TOOL_INSTALL == "" ]]
# then
#     # shellcheck disable=SC1091
#     . "$PROJECT_ROOT/libs/aws-tools.sh"
#     install_aws_tools
# fi

# if [[ $SKIP_TERRAFORM_TOOL_INSTALL == "" ]]
# then
#     # shellcheck disable=SC1091
#     . "$PROJECT_ROOT/libs/terraform-tools.sh"
#     install_terraform_tools
# fi

# if [[ $SKIP_MISC_TOOL_INSTALL == "" ]]
# then
#     # shellcheck disable=SC1091
#     . "$PROJECT_ROOT/libs/misc-tools.sh"
#     install_misc_tools
# fi

# # install git hooks

# printf "INFO: Installing Git hooks.\n"
# { # try
#     cd "$PROJECT_ROOT"
#     chmod +x libs/*.sh -R
#     cd .git/hooks
#     rm -rf pre-commit
#     ln -sfn ../../libs/pre-commit.sh pre-commit
#     cd "$PROJECT_ROOT"
# } || { # catch
#     printf "ERR: Unable to create symlink for Git pre-commit process, exiting with error"
#     exit
# }

# # Post-processing checks

# if [[ ! -f "$HOME/.aws/credentials" ]]
# then
#     printf "INFO: Looks like you do not yet have a \$HOME/.aws/credentials configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n"
# fi

# if [[ ! -f "$HOME/.terraformrc" ]]
# then
#     printf "INFO: Looks like you do not yet have a \$HOME/.terraformrc credentials configuration, pleaes follow https://confluence.techno.ingenico.com/display/PPS/Using+Shared+Modules+from+GitLab+Private+Registry#UsingSharedModulesfromGitLabPrivateRegistry-localhost before attempting to use Terraf.\n"
# fi

# printf "INFO: Please reload your shell to ensure PATH and TF_PLUGIN_CACHE_DIR variables are set.\n"

# printf "Done.\n"
