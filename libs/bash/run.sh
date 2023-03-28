#!/bin/bash -e

# Example usage:
# Note `--skip_*_tools` and `--update` can be used together to update specific tool groups
# ./libs/bash/run.sh
# ./libs/bash/run.sh --arch amd64 --platform darwin
# ./libs/bash/run.sh --arch amd64 --alt-arch arm --platform darwin
# ./libs/bash/run.sh --arch amd64 --platform darwin --update true
# ./libs/bash/run.sh --arch arm32 --platform linux
# ./libs/bash/run.sh --arch arm32 --platform linux --shell_profile "$HOME/.zshell_profile"
# ./libs/bash/run.sh --arch arm32 --platform linux --skip_misc_tools true
# ./libs/bash/run.sh --bin_dir "/usr/bin" --skip_aws_tools true --update true
# ./libs/bash/run.sh --skip_aws_tools true --update true
# ./libs/bash/run.sh --skip_system_tools true --skip_terraform_tools true --skip_misc_tools true

# cli arg parsing

## Internal VARs
declare ALTARCH
declare ARCH
declare BIN_DIR
declare ORIG_PWD
declare PLATFORM
declare PROJECT_ROOT
declare SHELL_PROFILE
declare SKIP_AWS_TOOLS
declare SKIP_MISC_TOOLS
declare SKIP_SYSTEM_TOOLS
declare SKIP_TERRAFORM_TOOLS

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

if [[ "$ARCH" == "" ]]
then
    ARCH="amd64"
fi

if [[ "$ALTARCH" == "" ]]
then
    ALTARCH="x86_64"
fi

if [[ "$PLATFORM" == "" ]]
then
    PLATFORM="linux"
fi

if [[ "$PROJECT_ROOT" == "" ]]
then
    PROJECT_ROOT=$(git rev-parse --show-toplevel)
fi

if [[ "$SHELL_PROFILE" == "" ]]
then
    SHELL_PROFILE="$HOME/.worldline_pps_profile"
fi

if [[ "${BIN_DIR}" == "" ]]
then
    # https://unix.stackexchange.com/questions/8656/usr-bin-vs-usr-local-bin-on-linux
    # path for binaries NOT managed by a system packagemanager
    BIN_DIR="/usr/local/bin"
fi

if [[ "$UPDATE" = "" ]]
then
    UPDATE="false"
fi

ORIG_PWD="$(pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel)
export ORIG_PWD
export PROJECT_ROOT

## output runtime configuration
printf "INFO: Executing with the following argument configurations.\n"
echo "ARCH: $ARCH"
echo "ALTARCH: $ALTARCH"
echo "BIN_DIR: $BIN_DIR"
echo "PLATFORM: $PLATFORM"
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "ORIG_PWD: $ORIG_PWD"
echo "SHELL_PROFILE: $SHELL_PROFILE"
echo "UPDATE: $UPDATE"

echo "SKIP_SYSTEM_TOOLS: $SKIP_SYSTEM_TOOLS"
echo "SKIP_AWS_TOOLS: $SKIP_AWS_TOOLS"
echo "SKIP_TERRAFORM_TOOLS: $SKIP_TERRAFORM_TOOLS"
echo "SKIP_MISC_TOOLS: $SKIP_MISC_TOOLS"

## Execute

printf "INFO: Changing to project root.\n"
cd "$PROJECT_ROOT" || exit 1

printf "INFO: Sourcing tool versions.sh in run.sh.\n"
# shellcheck disable=SC1091
source "./libs/bash/versions.sh"

# Does $SHELL_PROFILE exist?
if [[ ! -f $SHELL_PROFILE ]]
then 
    printf "INFO: Creating toolchain shell .profile at %s.\n" "$SHELL_PROFILE"
    touch "$SHELL_PROFILE" || exit 1

    printf "INFO: Add BIN_DIR to PATH via in %s.\n" "$SHELL_PROFILE"
    echo "export PATH=\$PATH:$BIN_DIR" >> "$SHELL_PROFILE"
    echo "export PATH=$PROJECT_ROOT/libs/bash" >> "$SHELL_PROFILE"
fi

# Add tribe profile to .bashrc if it exists
# Other tribes can add additional shell profiles as $HOME/[[business_unit]]_[[tribe]]_profile
# shellcheck disable=SC2143
if [[ -f "$HOME/.bashrc" && ! $(grep "source $SHELL_PROFILE" "$HOME/.bashrc") ]]
then
    printf "INFO: Adding source %s to %s.\n" "$SHELL_PROFILE" "$HOME/.bashrc"
    echo "source $SHELL_PROFILE" >> "$HOME/.bashrc"
    #shellcheck disable=SC1091
    source "$HOME/.bashrc" || exit 1
fi

# System tools MUST be first
if [[ $SKIP_SYSTEM_TOOLS == "" ]]
then
    cd "$PROJECT_ROOT/.tmp" || exit 1
    # shellcheck disable=SC1091
    source "../libs/bash/system_tools.sh"
    install_system_tools
fi

# Additional management sorted alphabetically
if [[ $SKIP_AWS_TOOLS == "" ]]
then
    cd "$PROJECT_ROOT/.tmp" || exit 1
    # shellcheck disable=SC1091
    source "../libs/bash/aws_tools.sh"
    install_aws_tools
fi

if [[ $SKIP_MISC_TOOLS == "" ]]
then
    cd "$PROJECT_ROOT/.tmp" || exit 1
    # shellcheck disable=SC1091
    source "../libs/bash/misc_tools.sh"
    install_misc_tools
fi

if [[ $SKIP_TERRAFORM_TOOLS == "" ]]
then
    cd "$PROJECT_ROOT/.tmp" || exit 1
    # shellcheck disable=SC1091
    source "../libs/bash/terraform_tools.sh"
    install_terraform_tools
fi

# Post-processing checks

printf "INFO: Sourcing %s\n" "$SHELL_PROFILE"
# shellcheck disable=SC1090
source "$SHELL_PROFILE" || exit 1

printf "INFO: Changing back to original working dir.\n"
cd "$ORIG_PWD" || exit 1

if [[ ! -f "$HOME/.aws/credentials" ]]
then
    printf "INFO: Looks like you do not yet have a \$HOME/.aws/credentials configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n"
fi

if [[ ! -f "$HOME/.terraformrc" ]]
then
    printf "INFO: Looks like you do not yet have a \$HOME/.terraformrc credentials configuration, pleaes follow https://confluence.techno.ingenico.com/display/PPS/Using+Shared+Modules+from+GitLab+Private+Registry#UsingSharedModulesfromGitLabPrivateRegistry-localhost before attempting to use Terraf.\n"
fi

printf "INFO: Please start your shell session to ensure the PATH value is reloaded.\n"

printf "Toolchain run.sh completed successfully.\n"
