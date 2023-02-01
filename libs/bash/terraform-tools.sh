#!/bin/bash

function configure_terraform_runtime() {
    # shellcheck disable=SC2143
    if [[ ! $(grep "export TF_PLUGIN_CACHE_DIR" "$SHELLRC") ]]
    then
        # source https://www.tailored.cloud/devops/cache-terraform-providers/
        printf "INFO: Configuring Terraform provider shared cache.\n"
        mkdir "$HOME/.terraform.d/plugin-cache/" || true
        echo "export TF_PLUGIN_CACHE_DIR=\"$HOME/.terraform.d/plugin-cache/\"" >> "$SHELLRC"
    fi
}

function python_based_terraform_tools() {
    if [[ ! $(which blast-radius) || "${UPDATE}" == "true" ]]
    then
        # We always want the latest vesrsion of tools installed via pip3
        printf "INFO: Installing Blast Radius viz tool.\n"
        # https://github.com/28mm/blast-radius
        pip3 install -U blastradius --user

        # Do diff distro's put the Python package bins in different locations?
        chmod +x "$HOME/.local/bin/blast-radius"
    fi

    if [[ ! $(which checkov) || "${UPDATE}" == "true" ]]
    then
        # We always want the latest vesrsion of tools installed via pip3
        printf "INFO: Installing Checkov compliance tool.\n"
        # https://github.com/bridgecrewio/checkov
        pip3 install -U checkov --user

        # Do diff distro's put the Python package bins in different locations?
        chmod +x "$HOME/.local/bin/checkov"
    fi
}

function tfenv_and_terraform() {
    if [[ (! $(which tfenv) && ! -d "$HOME/.tfenv" && ${TFENV_VER}) || "${UPDATE}" == "true" ]]
    then
        printf "INFO: Installing tfenv.\n"
        cd "$HOME" || exit
        rm -rf "$HOME/.tfenv" || true
        git clone https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
        cd .tfenv || exit

        sudo ln -sfn ~/.tfenv/bin/* /usr/local/bin || true
    elif [[ -d "$HOME/.tgenv" && ${TFENV_VER} && "${UPDATE}" == "true" ]]
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
    if [[ ! $(grep "export PATH=\$PATH:\$HOME/.tfenv/bin" "$SHELLRC") ]]
    then
        printf "INFO: Add tfenv %s PATH.\n" "$HOME/.tfenv/bin"
        echo "export PATH=\$PATH:\$HOME/.tfenv/bin" >> "$SHELLRC"
        #shellcheck disable=SC1090
        source "$SHELLRC"
    fi

    printf "INFO: Installing Terraform via tfenv.\n"
    tfenv install "${TF_VER}"
    tfenv use "${TF_VER}"
}

function tgenv_and_terragrunt() {
    if [[ (! $(which tfgnv) && ! -d "$HOME/.tgenv" && ${TGENV_VER}) || "${UPDATE}" == "true" ]]
    then
        printf "INFO: Installing tgenv.\n"
        cd "$HOME" || exit
        rm -rf "$HOME/.tgenv" || true
        git clone https://github.com/tgenv/tgenv.git "$HOME/.tgenv"
        cd .tgenv || exit
        sudo ln -s ~/.tgenv/bin/* /usr/local/bin || true
    elif [[ -d "$HOME/.tgenv" && ${TGENV_VER} && "${UPDATE}" == "true" ]]
    then
        printf "INFO: Updating tgenv.\n"
        cd "$HOME/.tgenv" || exit
        git reset master --hard
        git fetch --all --tags
        git checkout "v${TGENV_VER}"
        cd "$PROJECT_ROOT" || exit
    fi

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:\$HOME/.tgenv/bin" "$SHELLRC") ]]
    then
        printf "INFO: Add tgenv %s PATH.\n" "$HOME/.tgenv/bin"
        echo "export PATH=\$PATH:\$HOME/.tgenv/bin" >> "$SHELLRC"
        #shellcheck disable=SC1090
        source "$SHELLRC"
    fi

    printf "INFO: Installing Terragrunt via tgenv.\n"
    tgenv install "${TG_VER}"
    tgenv use "${TG_VER}"
}

function binary_based_tools() {
    if [[ ( ! $(which terrascan) && "${TRSCAN_VER}" ) || "${UPDATE}" = "true" ]]
    then
        printf "INFO: Installing terrascan.\n"
        curl -L "https://github.com/tenable/terrascan/releases/download/v${TRSCAN}/terrascan_${TRSCAN}_${PLATFORM^}_${ALTARCH}.tar.gz" -o terrascan.tar.gz
        tar -xf terrascan.tar.gz terrascan
        sudo install terrascan /usr/local/bin
        rm -rf terrascan*
    fi

    if [[ ( ! $(which tfsec) && "${TFSEC_VER}" ) || "${UPDATE}" = "true" ]]
    then
        printf "INFO: Installing tfsec.\n"
        curl -L "https://github.com/liamg/tfsec/releases/download/v${TFSEC_VER}/tfsec-${PLATFORM}-${ARCH}" -o "tfsec-${PLATFORM}-${ARCH}"
        sudo install "tfsec-${PLATFORM}-${ARCH}" /usr/local/bin/tfsec
        rm -rf tfsec*
    fi

    if [[ ( ! $(which infracost) && "${INFRACOST_VER}" ) || "${UPDATE}" = "true" ]]
    then
        printf "INFO: Installing infracost.\n"
        curl -L "https://github.com/infracost/infracost/releases/download/v${INFRACOST_VER}/infracost-${PLATFORM}-${ARCH}.tar.gz" -o infracost.tar.gz
        tar -xf infracost.tar.gz
        sudo install "infracost-${PLATFORM}-${ARCH}" /usr/local/bin/infracost
        rm -rf infracost*
    fi

    if [[ ( ! $(which tflint) && "${TFLINT_VER}" ) || "${UPDATE}" = "true" ]]
    then
        printf "INFO: Installing tflint.\n"
        curl -L "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VER}/tflint_${PLATFORM}_${ARCH}.zip" -o tflint.zip
        unzip tflint.zip
        sudo install tflint /usr/local/binUpdating
        rm -rf tflint*
    fi

    if [[ ( ! $(which terraform-docs) && "${TFDOCS_VER}" ) || "${UPDATE}" = "true" ]]
    then
        printf "INFO: Installing terraform-docs.\n"
        curl -L "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VER}/terraform-docs-v${TFDOCS_VER}-${PLATFORM}-${ARCH}.tar.gz" -o terraform-docs.tar.gz
        tar -xf terraform-docs.tar.gz terraform-docs
        sudo install terraform-docs /usr/local/bin/terraform-docs
        rm -rf terraform-docs*
    fi
}

# usage install_terraform_tools
function install_terraform_tools() {

    printf "INFO: Processing TERRAFORM tools.\n"

    # sorted in order of importance
    configure_terraform_runtime
    tfenv_and_terraform
    tgenv_and_terragrunt
    binary_based_tools
    python_based_terraform_tools

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output Terraform tool versions.\n"

    echo "checkov $(checkov --version)"
    echo "tfsec $(tfsec --version)"

    echo "terrascan $(terrascan version)"

    infracost --version
    terraform --version
    terragrunt --version
    tfenv --version
    tgenv --version
}
