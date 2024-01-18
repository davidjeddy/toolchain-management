#!/bin/bash

function install_aws_tools() {

    printf "INFO: Processing AWS tools.\n"

    # aws cli
    if [[ ( ! $(which aws) && "${AWSCLI_VER}") || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing aws cli.\n"
        curl -sL --show-error "https://awscli.amazonaws.com/awscli-exe-$PLATFORM-$ALTARCH-$AWSCLI_VER.zip" -o "awscliv2.zip"
        unzip -qq "awscliv2.zip"
        sudo ./aws/install -b "$BIN_DIR" || sudo ./aws/install -b "$BIN_DIR" --update
        rm -rf aws*

        # https://stackoverflow.com/questions/12806176/checking-for-installed-packages-and-if-not-found-install
        # shellcheck disable=SC2126
        if [[ $(which yum) && $(yum list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 1 ]]
        then
            echo "AWS CLI session-manager-plugin installed";
        else
            sudo yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
        fi
    fi

    # assitant tools
    if [[ ( ! $(which iam-policy-json-to-terraform) && "$IPJTT_VER") || $UPDATE == "true" ]]
    then
        printf "INFO: Installing iam-policy-json-to-terraform.\n"
        curl -sL --show-error "https://github.com/flosell/iam-policy-json-to-terraform/releases/download/$IPJTT_VER/iam-policy-json-to-terraform_$ARCH" -o "iam-policy-json-to-terraform"
        sudo install iam-policy-json-to-terraform "$BIN_DIR"
        rm -rf iam-policy-json-to-terraform*
    fi

    # https://pypi.org/project/onelogin-aws-cli/
    # `onelogin-aws-login` provided by package `onelogin-aws-cli`
    if [[ ! $(which onelogin-aws-login) && "${ONELOGIN_AWS_CLI_VER}" || "$UPDATE" == "true" ]]
    then
        printf "INFO: Remove old onelogin-aws-cli if it exists.\n"
        pip uninstall -y onelogin-aws-cli || true

        # We always want the latest vesrsion of tools installed via pip
        printf "INFO: Installing onelogin-aws-cli compliance tool.\n"
        # https://github.com/bridgecrewio/checkov
        pip install -U onelogin-aws-cli=="$ONELOGIN_AWS_CLI_VER" --user

        # Do diff distro's put the Python package bins in different locations?
        # Why does this package name entry script different than the package name?
        chmod +x ~/.local/bin/onelogin-aws-login
    fi

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output AWS tool versions.\n"

    echo "iam-policy-json-to-terraform $(iam-policy-json-to-terraform --version)"
    echo "onelogin-aws-cli $(pip show onelogin-aws-cli)"

    aws --version
}
