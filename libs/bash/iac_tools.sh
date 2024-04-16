#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
# shellcheck source=/home/jenkins/
source "$SHELL_PROFILE"

function configure_iac_runtime() {
    # shellcheck disable=SC2143
    if [[ ! $(grep "export TF_PLUGIN_CACHE_DIR" "$SHELL_PROFILE") ]]
    then
        # source https://www.tailored.cloud/devops/cache-terraform-providers/
        printf "INFO: Configuring Terraform provider shared cache.\n"
        mkdir -p ~/.terraform.d/plugin-cache/ || true
        echo "export TF_PLUGIN_CACHE_DIR=~/.terraform.d/plugin-cache/" >> "$SHELL_PROFILE"
    fi
}

function golang_based_iac_tools() {
    # Because pipelines do not have a full shell, be sure to include the PATH in the execution shell
    # shellcheck disable=SC1090
    source "$SHELL_PROFILE"
    
    # Always download kics to enable re/build of the query library on every install
    printf "INFO: Downloading kics archive.\n"
    mkdir -p "$WL_GC_TM_WORKSPACE/.tmp" || exit 1
    cd "$WL_GC_TM_WORKSPACE/.tmp" || exit 1
    # obtain source archive
    curl --location --silent --show-error "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" -o "kics.tar.gz"
    tar -xf kics.tar.gz

    # build executable if needed
    if [[ ( ! $(which kics) && $KICS_VER) || "$UPDATE" == "true" ]]
    then
        cd "kics-${KICS_VER}" || exit 1
        printf "INFO: Building kics. (If the process hangs, try disablig proxy/firewalls. Go needs the ability to download packages via ssh protocol.\n"
        # Make sure GO >=1.11 modules are enabled
        declare GO111MODULE
        export GO111MODULE="on"
        goenv exec go mod download -x
        goenv exec go build -o bin/kics cmd/console/main.go

        sudo install bin/kics "$BIN_DIR"
        cd "../" || exit 1

        kics version
    fi

    # Always rebuild KICS query library during an install
    rm -rf "$WL_GC_TM_WORKSPACE/libs/kics" || true
    mkdir -p "$WL_GC_TM_WORKSPACE/libs/kics"
    cp -rf "$WL_GC_TM_WORKSPACE/.tmp/kics-${KICS_VER}/assets" "$WL_GC_TM_WORKSPACE/libs/kics" || exit 1

    which kics
    kics version
}

function python_based_iac_tools() {
    if [[ ( ! $(which checkov) && "${CHECKOV_VER}" ) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Remove old Checkov if it exists.\n"
        pip uninstall -y checkov || true

        # We always want the latest vesrsion of tools installed via pip
        printf "INFO: Installing Checkov compliance tool.\n"
        # https://github.com/bridgecrewio/checkov
        pip install -U checkov=="$CHECKOV_VER"

        echo "checkov $(checkov --version)"
    fi

    # -----

    which checkov
    checkov --version
}

# TODO the following couple of functions are functionally the same, just different source project / target dir. Can we abstract this all?

function tfenv_and_terraform() {
    cd ~/ || exit 1

    if [[ ( ! $(which tfenv) && $TFENV_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing tfenv.\n"
        rm -rf ~/.tfenv || true
        git clone --quiet "https://github.com/tfutils/tfenv.git" ~/.tfenv
        cd ~/.tfenv || exit 1

        sudo ln -sfn ~/.tfenv/bin/* "$BIN_DIR" || true
    elif [[ -d ~/.tfenv && $TFENV_VER && "$UPDATE" == "true" ]]
    then
        printf "INFO: Updating tfenv.\n"
        cd ~/.tfenv || exit 1
        git reset master --hard
        git fetch --all --tags
        git checkout "v$TFENV_VER"
    fi

    cd "$WL_GC_TM_WORKSPACE" || exit 1

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:~/.tfenv/bin" "$SHELL_PROFILE") ]]
    then
        printf "INFO: Add tfenv bin dir to PATH via %s.\n" "$SHELL_PROFILE"
        echo "export PATH=\$PATH:~/.tfenv/bin" >> "$SHELL_PROFILE"
        #shellcheck disable=SC1090
        source "$SHELL_PROFILE"
    fi

    # install terraform version only if not already present on the host
    if [[ "$(tfenv list)" != *"$TF_VER"* ]]
    then
        printf "INFO: Installing Terraform via tfenv.\n"
        tfenv install "$TF_VER"
    fi

    tfenv use "$TF_VER"

    # -----

    which tfenv
    tfenv --version
    which terraform
    terraform --version
}

function tgenv_and_terragrunt() {
    cd ~/ || exit 1

    if [[ ( ! $(which tgenv) && $TGENV_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing tgenv.\n"
        rm -rf ~/.tgenv || true
        git clone --quiet "https://github.com/tgenv/tgenv.git" ~/.tgenv
        cd ~/.tgenv || exit

        sudo ln -s ~/.tgenv/bin/* "$BIN_DIR" || true
    elif [[ -d ~/.tgenv && $TGENV_VER && "$UPDATE" == "true" ]]
    then
        printf "INFO: Updating tgenv.\n"
        cd ~/.tgenv || exit
        git reset master --hard
        git fetch --all --tags
        git checkout "v$TGENV_VER"
    fi

    cd "$WL_GC_TM_WORKSPACE" || exit 1

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:~/.tgenv/bin" "$SHELL_PROFILE") ]]
    then
        printf "INFO: Add tgenv bindir to PATH via %s.\n" "$SHELL_PROFILE"
        echo "export PATH=\$PATH:~/.tgenv/bin" >> "$SHELL_PROFILE"
        #shellcheck disable=SC1090
        source "$SHELL_PROFILE"
    fi

    # install terragrunt version only if not already present on the host
    if [[ "$(tgenv list)" != *"$TG_VER"* ]]
    then
        printf "INFO: Installing Terragrunt via tgenv.\n"
        tgenv install "$TG_VER" 
    fi

    tgenv use "$TG_VER"

    # -----

    which tgenv
    tgenv --version
    which terragrunt
    terragrunt --version
}

# https://github.com/tofuutils/tofuenv#manual-linux-and-macos
function tofuenv_and_tofu() {
    cd ~/ || exit 1

    if [[ ( ! $(which tofuenv) && $TOFUENV_VER) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing tofuenv.\n"
        rm -rf ~/.tofuenv || true
        git clone --quiet https://github.com/tofuutils/tofuenv.git ~/.tofuenv
        cd ~/.tofuenv || exit 1
        git checkout "v$TOFUENV_VER"

        sudo ln -sfn ~/.tofuenv/bin/* "$BIN_DIR"
    elif [[ -d ~/.tofuenv && $TOFUENV_VER && "$UPDATE" == "true" ]]
    then
        printf "INFO: Updating tofuenv.\n"
        cd ~/.tofuenv || exit 1
        git reset master --hard
        git fetch --all --tags
        git checkout "v$TOFUENV_VER"
    fi

    cd "$WL_GC_TM_WORKSPACE" || exit 1

    # shellcheck disable=SC2143
    if [[ ! $(grep "export PATH=\$PATH:~/.tofuenv/bin" "$SHELL_PROFILE") ]]
    then
        printf "INFO: Add tofuenv bin dir to PATH via %s.\n" "$SHELL_PROFILE"
        echo "export PATH=\$PATH:~/.tofuenv/bin" >> "$SHELL_PROFILE"
        #shellcheck disable=SC1090
        source "$SHELL_PROFILE"
    fi

    # install OpenTofu version only if not already present on the host
    if [[ "$(tofuenv list)" != *"$TOFU_VER"* ]]
    then
        printf "INFO: Installing OpenTofu via tofuenv.\n"
        tofuenv install "$TOFU_VER"
    fi

    # -----

    which tofuenv
    tofuenv use "$TOFU_VER"
    which tofu
    tofu --version
}

function binary_based_tools() {
    if [[ ( ! $(which tfsec) && "$TFSEC_VER" ) || "$UPDATE" = "true" ]]
    then
        printf "INFO: Installing tfsec.\n"
        curl --location --silent --show-error "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VER}/tfsec-${PLATFORM}-${ALT_ARCH}" -o "tfsec"
        sudo install --target-directory="$BIN_DIR" tfsec
        rm -rf tfsec*
    fi

    if [[ ( ! $(which trivy) && "$TRIVY_VER" ) || "$UPDATE" = "true" ]]
    then
        printf "INFO: Installing trivy (tfsec successor).\n"
        if [[ $(which apt) ]]
        then
          echo "INFO: Installing Trivy for x86 based apt managed system."
          curl --location --silent --show-error "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VER}/trivy_${TRIVY_VER}_${PLATFORM^}-64bit.deb" -o "trivy.deb"
          sudo apt install ./trivy.deb
        elif [[ $(which dnf) && $ARCH == 'aarch64' ]]
        then
          echo "INFO: Installing Trivy for ARM based dnf managed system."
          sudo rpm -Uvh --replacepkgs "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VER}/trivy_${TRIVY_VER}_${PLATFORM^}-${ALT_ARCH^^}.rpm"
        elif [[ $(which yum) && $ARCH == 'x86_64' ]]
        then
          # https://unix.stackexchange.com/questions/43114/how-to-install-remove-upgrade-rpm-packages-on-red-hat
          echo "INFO: Installing Trivy for X86 based rpm managed system."
          # Because RPM wants to be a complete pain and just update the package, so fine, we will force a non-failure code return
          # The aws-bambora Jenkins worker is going away soon enough anyways.
          sudo rpm -Uvh --replacepkgs "https://github.com/aquasecurity/trivy/releases/download/v0.49.1/trivy_0.49.1_Linux-64bit.rpm" || true
        else
          echo "INFO: Unable to install trivy. No compatibile system and package manager found."
          exit 1
        fi

        rm -rf trivy*
    fi

    if [[ ( ! $(which infracost) && "$INFRACOST_VER" ) || "$UPDATE" = "true" ]]
    then
        printf "INFO: Installing infracost.\n"
        declare INFRACOST_URL
        INFRACOST_URL="https://github.com/infracost/infracost/releases/download/v${INFRACOST_VER}/infracost-${PLATFORM}-${ALT_ARCH}.tar.gz"
        echo "INFO: INFRACOST_URL: $INFRACOST_URL"

        curl --location --silent --show-error "$INFRACOST_URL" -o "infracost.tar.gz"
        tar -xf infracost.tar.gz
        mv "infracost-$PLATFORM-$ALT_ARCH" infracost || exit 1
        sudo rm -rf "$BIN_DIR/infracost" || true
        sudo install --target-directory="$BIN_DIR" infracost
        rm -rf infracost*
    fi

    if [[ ( ! $(which tflint) && "$TFLINT_VER" ) || "$UPDATE" = "true" ]]
    then
        # Must use {} around PLATFORM else Bash thinks varitable variable is presetn
        printf "INFO: Installing tflint.\n"
        declare TFLINT_URL
        TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VER}/tflint_${PLATFORM}_${ALT_ARCH}.zip"
        echo "INFO: TFLINT_URL: $TFLINT_URL"

        curl --location --silent --show-error "$TFLINT_URL" -o "tflint.zip"
        unzip -qq "tflint.zip"
        sudo rm -rf "$BIN_DIR/tflint" || true
        sudo install --target-directory="$BIN_DIR" tflint
        rm -rf tflint*
    fi

    if [[ ( ! $(which terraform-docs) && "$TFDOCS_VER" ) || "$UPDATE" = "true" ]]
    then
        printf "INFO: Installing terraform-docs.\n"
        declare TFDOCS_URL
        TFDOCS_URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VER}/terraform-docs-v${TFDOCS_VER}-${PLATFORM}-${ALT_ARCH}.tar.gz"
        echo "INFO: TFDOCS_URL: $TFDOCS_URL"

        curl --location --silent --show-error "$TFDOCS_URL" -o "terraform-docs.tar.gz"
        tar -xf terraform-docs.tar.gz terraform-docs
        sudo rm -rf "$BIN_DIR/terraform-docs" || true
        sudo install --target-directory="$BIN_DIR" terraform-docs
        rm -rf terraform-docs*
    fi

    # -----

    which tfsec
    tfsec -version
    which trivy
    trivy --version
    which infracost
    infracost --version
    which tflint
    tflint --version
    which terraform-docs
    terraform-docs --version
}

function install_iac_tools() {

    printf "INFO: Processing TERRAFORM tools.\n"

    # do not change order
    binary_based_tools
    configure_iac_runtime
    golang_based_iac_tools
    python_based_iac_tools
    tfenv_and_terraform
    tgenv_and_terragrunt
    tofuenv_and_tofu
}
