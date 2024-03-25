#!/usr/bin/env bash

set -e

function install_cloud_tools() {

    printf "INFO: Processing cloud tools.\n"

    # aws cli
    if [[ ( ! $(which aws) && "${AWSCLI_VER}") || "$UPDATE" == "true" ]]
    then
        curl --location --silent --show-error "https://awscli.amazonaws.com/awscli-exe-$PLATFORM-$ARCH.zip" -o "awscliv2.zip"
        unzip -qq awscliv2.zip
        sudo ./aws/install --bin-dir "$BIN_DIR" || sudo ./aws/install --bin-dir "$BIN_DIR" --update
        rm -rf aws*

        aws --version
    fi

    # aws - ssm-session-manager plugin
    # https://stackoverflow.com/questions/12806176/checking-for-installed-packages-and-if-not-found-install
    # shellcheck disable=SC2126
    if [[ $(which dnf) && $(dnf list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
    then
        echo "INFO: Installing AWS CLI session-manager-plugin via dnf system package manager.";
        # Fedora
        if [[ $(uname -m) == "x86_64" ]]
        then
            ## arm64
            sudo dnf install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
        elif [[ $(uname -m) == "aarch64" ]]
        then
            ## amd64
            sudo dnf install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_$ALT_ARCH/session-manager-plugin.rpm"
        else
            prinf "ALERT: Unable to determine CPU architecture for AWS session-manager-plugin.\n"
        fi
    elif [[ $(which yum) && $(yum list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
    then
        # RHEL
        echo "INFO: Installing AWS CLI session-manager-plugin via yum system package manager.";
        sudo rpm -Uvh "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
    elif [[ $(which apt) && $(apt list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
    then
        # Debian
        echo "INFO: Installing AWS CLI session-manager-plugin via apt system package manager.";
        echo "WARN: Actually, no. Please submit MR to support Debian based systems.";
        exit 1
    else
        # Other
        printf "WARN: AWS CLI session-manager-plugin NOT installed. Please install manually via https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html\n"
    fi

    # assitant tools
    if [[ ( ! $(which iam-policy-json-to-terraform) && "$IPJTT_VER") || $UPDATE == "true" ]]
    then
        # Request submitted to support ARM https://github.com/flosell/iam-policy-json-to-terraform/issues/107
        if [[ $ARCH == "amd64" ]]
        then
            printf "INFO: Installing iam-policy-json-to-terraform.\n"
            curl --location --silent --show-error "https://github.com/flosell/iam-policy-json-to-terraform/releases/download/$IPJTT_VER/iam-policy-json-to-terraform_$ARCH" -o "iam-policy-json-to-terraform"
            sudo install iam-policy-json-to-terraform "$BIN_DIR"
            rm -rf iam-policy-json-to-terraform*
        fi
    fi

    # https://pypi.org/project/onelogin-aws-cli/
    # `onelogin-aws-login` provided by package `onelogin-aws-cli`
    if [[ ! $(which onelogin-aws-login) && "${ONELOGIN_AWS_CLI_VER}" || "$UPDATE" == "true" ]]
    then
        printf "INFO: Remove old onelogin-aws-cli if it exists.\n"
        pip uninstall -y onelogin-aws-cli || true

        # We always want the latest vesrsion of tools installed via pip
        printf "INFO: Installing onelogin-aws-cli compliance tool.\n"
        pip install -U onelogin-aws-cli=="$ONELOGIN_AWS_CLI_VER"

        onelogin-aws-login --version
        echo "onelogin-aws-cli $(pip show onelogin-aws-cli)"
    fi

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output AWS tool versions.\n"

    if [[ ! $ARCH == "aarch64" ]]
    then
        # Request submitted to support ARM https://github.com/flosell/iam-policy-json-to-terraform/issues/107
        echo "iam-policy-json-to-terraform $(iam-policy-json-to-terraform --version)" 
    fi
}
