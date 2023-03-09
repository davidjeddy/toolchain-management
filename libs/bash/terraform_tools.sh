#!/bin/bash

function configure_terraform_runtime() {
    # shellcheck disable=SC2143
    if [[ ! $(grep "export TF_PLUGIN_CACHE_DIR" "$SHELL_PROFILE") ]]
    then
        # source https://www.tailored.cloud/devops/cache-terraform-providers/
        printf "INFO: Configuring Terraform provider shared cache.\n"
        mkdir "$HOME/.terraform.d/plugin-cache/" || true
        echo "export TF_PLUGIN_CACHE_DIR=\"$HOME/.terraform.d/plugin-cache/\"" >> "$SHELL_PROFILE"
    fi
}

function golang_based_terraform_tools() {
        # Because pipelines do not have a full shell, be sure to include the PATH in the execution shell
        # shellcheck disable=SC1090
        source "$SHELL_PROFILE"

        printf "INFO: Installing kics.\n"
        curl -sL --show-error "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" -o "kics.tar.gz"
        tar -xf kics.tar.gz
        cd "kics-${KICS_VER}" || exit 1

        # the build process is extracted from https://github.com/Checkmarx/kics/blob/acc15c70004cfd7a94def4887cc7c57ae470fcc5/docker/Dockerfile.debian
        export CGO_ENABLED=0
        export GOARCH="amd64"
        export GOOS="linux"
        export GOPATH"=$HOME/go"

        go mod download -x

        go build \
            -a -installsuffix cgo \
            -o bin/kics cmd/console/main.go

        # install KICS assets
        mkdir -p "$PROJECT_ROOT/libs/kics"
        cp -rf "assets" "$PROJECT_ROOT/libs/kics" || exit 1

        sudo install bin/kics "$BIN_DIR"

        printf "INFO: Clearn up KICS resources"
        cd "$PROJECT_ROOT/.tmp" || exit 1
        rm -rf kics*
}

function python_based_terraform_tools() {
    # Because pipelines do not have a full shell, be sure to include the PATH to the Python binaries
    # shellcheck disable=SC2155
    export PATH=$PATH:/home/$(whoami)/.local/bin

    if [[ ! $(which blast-radius) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Remove old Blast Radius viz tool if it exists.\n"
        pip3 uninstall -y blastradius || true

        # We always want the latest vesrsion of tools installed via pip3
        printf "INFO: Installing Blast Radius viz tool.\n"
        # https://github.com/28mm/blast-radius
        pip3 install -U blastradius --user

        # Do diff distro's put the Python package bins in different locations?
        chmod +x "$HOME/.local/bin/blast-radius"
    fi

    if [[ ! $(which checkov) && "${CHECKOV_VER}" || "$UPDATE" == "true" ]]
    then
        printf "INFO: Remove old Checkovl if it exists.\n"
        pip3 uninstall -y checkov || true

        # We always want the latest vesrsion of tools installed via pip3
        printf "INFO: Installing Checkov compliance tool.\n"
        # https://github.com/bridgecrewio/checkov
        pip3 install -U checkov=="$CHECKOV_VER" --user

        # Do diff distro's put the Python package bins in different locations?
        chmod +x "$HOME/.local/bin/checkov"
    fi
}

function tfenv_and_terraform() {
    if [[ ( !  $(which tfenv) && ! -d "$HOME/.tfenv" && $TFENV_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing tfenv.\n"
        cd "$HOME" || exit
        rm -rf "$HOME/.tfenv" || true
        git clone https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
        cd .tfenv || exit

        sudo ln -sfn ~/.tfenv/bin/* "$BIN_DIR" || true
    elif [[ -d "$HOME/.tgenv" && $TFENV_VER && "$UPDATE" == "true" ]]
    then
        printf "INFO: Updating tfenv.\n"
        export PATH=$PATH:$HOME/.tfenv/bin
        cd "$HOME/.tfenv" || exit 
        git reset master --hard
        git fetch --all --tags
        git checkout "v$TFENV_VER"
        cd "$PROJECT_ROOT" || exit
    fi

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:\$HOME/.tfenv/bin" "$SHELL_PROFILE") ]]
    then
        printf "INFO: Add tfenv bindir to PATH via %s.\n" "$SHELL_PROFILE"
        echo "export PATH=\$PATH:\$HOME/.tfenv/bin" >> "$SHELL_PROFILE"
        #shellcheck disable=SC1090
        source "$SHELL_PROFILE"
    fi

    printf "INFO: Installing Terraform via tfenv.\n"
    tfenv install "$TF_VER"
    tfenv use "$TF_VER"
}

function tgenv_and_terragrunt() {
    if [[ ( !  $(which tfgnv) && ! -d "$HOME/.tgenv" && $TGENV_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing tgenv.\n"
        cd "$HOME" || exit
        rm -rf "$HOME/.tgenv" || true
        git clone https://github.com/tgenv/tgenv.git "$HOME/.tgenv"
        cd .tgenv || exit
        sudo ln -s ~/.tgenv/bin/* "$BIN_DIR" || true
    elif [[ -d "$HOME/.tgenv" && $TGENV_VER && "$UPDATE" == "true" ]]
    then
        printf "INFO: Updating tgenv.\n"
        cd "$HOME/.tgenv" || exit
        git reset master --hard
        git fetch --all --tags
        git checkout "v$TGENV_VER"
        cd "$PROJECT_ROOT" || exit
    fi

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:\$HOME/.tgenv/bin" "$SHELL_PROFILE") ]]
    then
        printf "INFO: Add tgenv bindir to PATH via %s.\n" "$SHELL_PROFILE"
        echo "export PATH=\$PATH:\$HOME/.tgenv/bin" >> "$SHELL_PROFILE"
        #shellcheck disable=SC1090
        source "$SHELL_PROFILE"
    fi

    printf "INFO: Installing Terragrunt via tgenv.\n"
    tgenv install "$TG_VER"
    tgenv use "$TG_VER"
}

function binary_based_tools() {
    if [[ ( ! $(which terrascan) && "${TRSCAN_VER}" ) || "$UPDATE" = "true" ]]
    then
        # this one ia problem child due to the URL and non-standard use of x86_64 > amd64. AND the '_' delimiter makes bash think variable variables are present
        printf "INFO: Installing terrascan.\n"
        curl -sL --show-error "https://github.com/tenable/terrascan/releases/download/v${TRSCAN_VER}/terrascan_${TRSCAN_VER}_${PLATFORM}_${ALTARCH}.tar.gz" -o "terrascan.tar.gz"
        tar -xf terrascan.tar.gz terrascan
        sudo rm -rf "$BIN_DIR/terrascan" || true
        sudo install --target-directory="$BIN_DIR" terrascan
        rm -rf terrascan*
    fi

    if [[ ( ! $(which tfsec) && "$TFSEC_VER" ) || "$UPDATE" = "true" ]]
    then
        printf "INFO: Installing tfsec.\n"
        curl -sL --show-error "https://github.com/liamg/tfsec/releases/download/v$TFSEC_VER/tfsec-$PLATFORM-$ARCH" -o "tfsec"
        # no unpacking needed, the download is a binary
        sudo rm -rf "$BIN_DIR/tfsec" || true
        sudo install --target-directory="$BIN_DIR" tfsec
        rm -rf tfsec*
    fi

    if [[ ( ! $(which infracost) && "$INFRACOST_VER" ) || "$UPDATE" = "true" ]]
    then
        printf "INFO: Installing infracost.\n"
        curl -sL --show-error "https://github.com/infracost/infracost/releases/download/v$INFRACOST_VER/infracost-$PLATFORM-$ARCH.tar.gz" -o "infracost.tar.gz"
        tar -xf infracost.tar.gz
        mv "infracost-$PLATFORM-$ARCH" infracost || exit 1
        sudo rm -rf "$BIN_DIR/infracost" || true
        sudo install --target-directory="$BIN_DIR" infracost
        rm -rf infracost*
    fi

    if [[ ( ! $(which tflint) && "$TFLINT_VER" ) || "$UPDATE" = "true" ]]
    then
        # Must use {} around PLATFORM else Bash thinks varitable variable is presetn
        printf "INFO: Installing tflint.\n"
        curl -sL --show-error "https://github.com/terraform-linters/tflint/releases/download/v$TFLINT_VER/tflint_${PLATFORM}_$ARCH.zip" -o "tflint.zip"
        unzip -qq "tflint.zip"
        sudo rm -rf "$BIN_DIR/tflint" || true
        sudo install --target-directory="$BIN_DIR" tflint
        rm -rf tflint*
    fi

    if [[ ( ! $(which terraform-docs) && "$TFDOCS_VER" ) || "$UPDATE" = "true" ]]
    then
        printf "INFO: Installing terraform-docs.\n"
        curl -sL --show-error "https://github.com/terraform-docs/terraform-docs/releases/download/v$TFDOCS_VER/terraform-docs-v$TFDOCS_VER-$PLATFORM-$ARCH.tar.gz" -o "terraform-docs.tar.gz"
        tar -xf terraform-docs.tar.gz terraform-docs
        sudo rm -rf "$BIN_DIR/terraform-docs" || true
        sudo install --target-directory="$BIN_DIR" terraform-docs
        rm -rf terraform-docs*
    fi
}

function install_terraform_tools() {

    printf "INFO: Processing TERRAFORM tools.\n"

    # do not change order
    configure_terraform_runtime
    tfenv_and_terraform
    tgenv_and_terragrunt
    binary_based_tools
    python_based_terraform_tools

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output Terraform tool versions.\n"

    echo "blast-radius --latest version available--"
    echo "checkov $(checkov --version)"
    echo "tfsec $(tfsec --version)"

    echo "terrascan $(terrascan version)"

    infracost --version
    terraform --version
    terragrunt --version
    tfenv --version
    tgenv --version

    kics version
}
