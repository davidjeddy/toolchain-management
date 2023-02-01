#!/bin/bash

# usage install_aws_tools
function install_aws_tools() {

    printf "INFO: Processing AWS tools.\n"

    # aws cli
    if [[ (! $(which aws) && "${AWS_VER}") || "${UPDATE}" == "true" ]]
    then
        printf "INFO: Installing aws cli.\n"
        sudo rm -rf /usr/local/aws-cli || true
        curl "https://awscli.amazonaws.com/awscli-exe-${PLATFORM}-${ALTARCH}-${AWSCLI_VER}.zip" -o "awscliv2.zip"
        unzip -o awscliv2.zip
        sudo ./aws/install || sudo ./aws/install --update
        rm -rf aws*
    fi

    # assitant tools
    if [[ (! $(which iam-policy-json-to-terraform) && "${IPJTT_VER}") || ${UPDATE} == "true" ]]
    then
        printf "INFO: Installing iam-policy-json-to-terraform.\n"
        curl -L "https://github.com/flosell/iam-policy-json-to-terraform/releases/download/${IPJTT_VER}/iam-policy-json-to-terraform_${ARCH}" -o "iam-policy-json-to-terraform"
        sudo install iam-policy-json-to-terraform /usr/local/bin
        rm -rf iam-policy-json-to-terraform*
    fi

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output AWS tool versions.\n"

    echo "iam-policy-json-to-terraform $(iam-policy-json-to-terraform --version)"

    aws --version
}
