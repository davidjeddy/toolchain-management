#!/bin/bash

# Terraform related tools
TFENV_VER="3.0.0"
TF_VER="1.3.0"
TGENV_VER="0.0.3"
TG_VER="0.42.5"

INFRACOST_VER="0.10.15"
TFDOCS_VER="0.16.0"
TFLINT_VER="0.43.0"
TFSEC_VER="1.22.0"
TRSCAN="1.17.1"

# usage install_terraform_tools
function install_terraform_tools() {
    # Terraform provider cache configuration
    # source https://www.tailored.cloud/devops/cache-terraform-providers/
    printf "INFO: Checking if a shared Terraform provider cache is configured.\n"
    # shellcheck disable=SC2143
    if [[ ! $(grep "export TF_PLUGIN_CACHE_DIR" "$HOME/$SHELLRC") ]]
    then
        mkdir "$HOME/.terraform.d/plugin-cache/"
        printf "INFO: Add Terraform cache dir %s to PATH.\n" "$HOME/.local/bin"
        echo "export TF_PLUGIN_CACHE_DIR=\"$HOME/.terraform.d/plugin-cache/\"" >> "$HOME/$SHELLRC"
        #shellcheck disable=SC1090
        source "$HOME/$SHELLRC"
    fi

    # Python3 based tools

    if [[ ! $(which blast-radius) ]]
    then
        # We always want the latest vesrsion of tools installed via pip3
        printf "INFO: Installing Blast Radius viz tool.\n"
        # https://github.com/28mm/blast-radius
        pip3 install -U blastradius --user
        chmod +x "$HOME/.local/bin/blast-radius"
    fi

    if [[ ! $(which checkov) ]]
    then
        # We always want the latest vesrsion of tools installed via pip3
        printf "INFO: Installing Checkov compliance tool.\n"
        # https://github.com/bridgecrewio/checkov
        pip3 install -U checkov --user
        chmod +x "$HOME/.local/bin/checkov"
    fi

    # Terraform related binary tools

    # install OR update if version defined != version installed:
    # if [[ ! $(which terrascan) && "${TRSCAN_VER}" || ! $(which tfsec) && "${TRSCAN_VER}" ]]

    if [[ ! $(which tfenv) && ! -d "$HOME/.tfenv" && ${TFENV_VER} ]]
    then
        printf "INFO: Installing tfenv.\n"
        cd "$HOME" || exit
        git clone https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
        cd .tfenv || exit

        sudo ln -sfn ~/.tfenv/bin/* /usr/local/bin
    elif [[ -d "$HOME/.tgenv" && ${TFENV_VER} ]]
    then
        printf "INFO: Updating tfenv.\n"
        export PATH=$PATH:$HOME/.tfenv/bin
        cd "$HOME/.tfenv" || exit 
        git reset master --hard
        git fetch --all --tags
        git checkout "v${TFENV_VER}"
        cd "$PROJECT_ROOT" || exit
    fi

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:\$HOME/.tfenv/bin" "$HOME/$SHELLRC") ]]
    then
        printf "INFO: Add Python3 %s PATH.\n" "$HOME/.tfenv/bin"
        echo "export PATH=\$PATH:\$HOME/.tfenv/bin" >> "$HOME/$SHELLRC"
        #shellcheck disable=SC1090
        source "$HOME/$SHELLRC"
    fi

    printf "INFO: Installing Terraform via tfenv.\n"
    tfenv install "${TF_VER}"
    tfenv use "${TF_VER}"

    if [[ ! $(which tfgnv) && ! -d "$HOME/.tgenv" && ${TGENV_VER} ]]
    then
        printf "INFO: Installing tgenv.\n"
        cd "$HOME" || exit
        git clone https://github.com/cunymatthieu/tgenv.git "$HOME/.tgenv"
        cd .tgenv || exit
        sudo ln -s ~/.tgenv/bin/* /usr/local/bin

    elif [[ -d "$HOME/.tgenv" && ${TGENV_VER} ]]
    then
        printf "INFO: Updating tgenv.\n"
        cd "$HOME/.tgenv" || exit
        git reset master --hard
        git fetch --all --tags
        git checkout "v${TGENV_VER}"
        cd "$PROJECT_ROOT" || exit
    fi

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:\$HOME/.tgenv/bin" "$HOME/$SHELLRC") ]]
    then
        printf "INFO: Add tgenv %s PATH.\n" "$HOME/.tgenv/bin"
        echo "export PATH=\$PATH:\$HOME/.tgenv/bin" >> "$HOME/$SHELLRC"
        #shellcheck disable=SC1090
        source "$HOME/$SHELLRC"
    fi

    printf "INFO: Installing Terragrunt via tgenv.\n"
    tgenv install "${TG_VER}"
    tgenv use "${TG_VER}"

    # this is a problem child. Different platform/arch naming, different CLI arg format
    if [[ ! $(which terrascan) && "${TRSCAN_VER}" ]]
    then
        printf "INFO: Installing terrascan.\n"
        curl -L "https://github.com/tenable/terrascan/releases/download/v${TRSCAN}/terrascan_${TRSCAN}_${PLATFORM^}_x86_64.tar.gz" -o terrascan.tar.gz
        tar -xf terrascan.tar.gz terrascan
        sudo install terrascan /usr/local/bin
        rm -rf terrascan*
    fi

    if [[ ! $(which tfsec) && "${TFSEC_VER}" ]]
    then
        printf "INFO: Installing tfsec.\n"
        curl -L "https://github.com/liamg/tfsec/releases/download/v${TFSEC_VER}/tfsec-${PLATFORM}-${ARCH}" -o "tfsec-${PLATFORM}-${ARCH}"
        sudo install "tfsec-${PLATFORM}-${ARCH}" /usr/local/bin/tfsec
        rm -rf tfsec*
    fi

    if [[ ! $(which infracost) && "${INFRACOST_VER}" ]]
    then
        printf "INFO: Installing infracost.\n"
        curl -L "https://github.com/infracost/infracost/releases/download/v${INFRACOST_VER}/infracost-${PLATFORM}-${ARCH}.tar.gz" -o infracost.tar.gz
        tar -xf infracost.tar.gz
        sudo install "infracost-${PLATFORM}-${ARCH}" /usr/local/bin/infracost
        rm -rf infracost*
    else
        printf "INFO: Updating infracost.\n"
        curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
    fi

    if [[ ! $(which tflint) && "${TFLINT_VER}" ]]
    then
        printf "INFO: Installing tflint.\n"
        curl -L "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VER}/tflint_${PLATFORM}_${ARCH}.zip" -o tflint.zip
        unzip tflint.zip
        sudo install tflint /usr/local/binUpdating
        rm -rf tflint*
    fi

    if [[ ! $(which terraform-docs) && "${TFDOCS_VER}" ]]
    then
        printf "INFO: Installing terraform-docs.\n"
        curl -L "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VER}/terraform-docs-v${TFDOCS_VER}-${PLATFORM}-${ARCH}.tar.gz" -o terraform-docs.tar.gz
        tar -xf terraform-docs.tar.gz terraform-docs
        sudo install terraform-docs /usr/local/bin/terraform-docs
        rm -rf terraform-docs*
    fi

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output tool version.\n"

    echo "checkov $(checkov --version)"

    infracost --version

    terraform --version
    terragrunt --version
    tfenv --version

    terrascan version
}
