#!/bin/bash

# AWS Tools

# https://github.com/flosell/iam-policy-json-to-terraform/releases
IPJTT=1.8.1

# usage install_aws_tools
function install_aws_tools() {

    if [[ ! $(which iam-policy-json-to-terraform) && "${IPJTT}" ]]
    then
        printf "INFO: Installing iam-policy-json-to-terraform.\n"
        curl -L "https://github.com/flosell/iam-policy-json-to-terraform/releases/download/${IPJTT}/iam-policy-json-to-terraform_${ARCH}" -o "iam-policy-json-to-terraform"
        sudo install iam-policy-json-to-terraform /usr/local/bin
        rm -rf iam-policy-json-to-terraform*
    fi

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output tool version.\n"
    aws --version

}
