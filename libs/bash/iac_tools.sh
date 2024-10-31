#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

function install_additional_iac_tools() {
    printf "INFO: starting install_additional_tools()\n"

    {
        rm -rf "$HOME/.kics" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.kics-version)" "https://github.com/Checkmarx/kics.git" "$HOME/.kics"
        cd "$HOME/.kics" || exit 1

        # weird but ok, we need to understand Golang's build process better; or switch to using the container build of kics
        GOROOT="$(pwd)"
        export GOROOT
        go mod vendor
        unset GOROOT

        CGO_ENABLED=0 go build \
            -a -installsuffix cgo \
            -o bin/kics cmd/console/main.go
        echo "export PATH=$HOME/.kics/bin:\$PATH" >> "$HOME/.bashrc"
        printf "INFO: Kics build and install completed.\n"

        rm -rf "$HOME/.tfenv" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tfsec-version)" "https://github.com/tfutils/tfenv.git" "$HOME/.tfenv"
        echo "export PATH=$HOME/.tfenv/bin:\$PATH" >> "$HOME/.bashrc"
        printf "INFO: tfenv install completed.\n"

        rm -rf "$HOME/.tgenv" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tgenv-version)" "https://github.com/tgenv/tgenv.git" "$HOME/.tgenv"
        echo "export PATH=$HOME/.tgenv/bin:\$PATH" >> "$HOME/.bashrc"
        printf "INFO: tgenv install completed.\n"

        rm -rf "$HOME/.tofuenv" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tofuenv-version)" "https://github.com/tofuutils/tofuenv.git" "$HOME/.tofuenv"
        echo "export PATH=$HOME/.tofuenv/bin:\$PATH" >> "$HOME/.bashrc"
        printf "INFO: tofuenv install completed.\n"

        rm -rf "$HOME/.xeol" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.xeol-version)" "https://github.com/xeol-io/xeol.git" "$HOME/.xeol"
        cd "$HOME/.xeol" || exit
        ./install.sh
        echo "export PATH=$HOME/.xeol/bin:\$PATH" >> "$HOME/.bashrc"
        printf "INFO: xeol install completed.\n"

        cd "$WL_GC_TM_WORKSPACE"

        # shellcheck disable=SC1090
        source "$SESSION_SHELL" || exit 1

        # shellcheck disable=SC2046
        tfenv install "$(cat "$WL_GC_TM_WORKSPACE"/.terraform-version)"

        # shellcheck disable=SC2046
        tfenv use "$(cat "$WL_GC_TM_WORKSPACE"/.terraform-version)"

        # shellcheck disable=SC2046
        tgenv install "$(cat "$WL_GC_TM_WORKSPACE"/.terragrunt-version)"

        # shellcheck disable=SC2046
        tgenv use "$(cat "$WL_GC_TM_WORKSPACE"/.terragrunt-version)"

        # shellcheck disable=SC2046
        tofuenv install "$(cat "$WL_GC_TM_WORKSPACE"/.tofu-version)"

        # shellcheck disable=SC2046
        tofuenv use "$(cat "$WL_GC_TM_WORKSPACE"/.tofu-version)"
    } || {
        printf "ERR: Unable to install additional iac tools.\n"
        exit 1
    }
}

function install_kics_query_library() {
    printf "INFO: starting install_kics_query_library()\n"

    # Even with KICS being installed via Aqua we still need the query libraries
    printf "INFO: Processing KICS query library.\n"

    # TODO Do we still need this?
    # Get version of KICS being used from aqua.yaml configuration
    declare KICS_VER
    KICS_VER="$(cat "$WL_GC_TM_WORKSPACE"/.kics-version)"
    printf "INFO: KICS version detected: %s\n" "$KICS_VER"

    # Automation can target `$HOME/.kics-installer/target_query_libs`
    # TODO Do we still need this?
    if [[ ! -d $HOME/.kics-installer/kics-"${KICS_VER}" ]]
    then
        printf "INFO: Installing missing KICS query library into %s.\n" "$HOME/.kics-installer"
        printf "WARN: If the process hangs, try disablig proxy/firewalls/vpn. Golang needs the ability to download packages via ssh protocol.\n"

        curl \
            --location \
            --output "kics-${KICS_VER}.tar.gz" \
            --show-error \
            "https://github.com/Checkmarx/kics/archive/refs/tags/${KICS_VER}.tar.gz"
        tar -xf kics-"${KICS_VER}".tar.gz
        # 'cause WHY TF does the dir not have th `v` when the tag, the archive, the --version output ALL HAVE THE LEADING V! WHY does the dir not?!
        KICS_VER=${KICS_VER#*v}

        if [[ ! -d "$HOME/.kics-installer/target_query_libs" ]]
        then 
            mkdir -p "$HOME/.kics-installer/target_query_libs"
        fi

        cp -rf ./kics-"${KICS_VER}"/assets/queries/ "$HOME/.kics-installer/target_query_libs"
        ls -lah

        cd "$WL_GC_TM_WORKSPACE" || exit 1
    fi

    # shellcheck disable=SC2088,SC2143
    if [[ -f "${SESSION_SHELL}" && ! $(grep "export TF_PLUGIN_CACHE_DIR" "${SESSION_SHELL}")  ]]
    then
        # source https://www.tailored.cloud/devops/cache-terraform-providers/
        printf "INFO: Configuring Terraform provider shared cache.\n"
        mkdir -p "$HOME/.terraform.d/plugin-cache/" || true
        echo "export TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache/" >> "${SESSION_SHELL}"
    fi

    # WARNs
    if [[ ! -f $HOME/.aws/credentials && $(whoami) != 'jenkins' ]]
    then
        printf "INFO: Looks like you do not yet have a %s configured, pleaes run the AWS configuration process as detailed here https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.\n" "$HOME/.aws/credentials"
    fi

    if [[ ! -f $HOME/.terraformrc && $(whoami) != 'jenkins' ]]
    then
        printf "INFO: Looks like you do not yet have a %s credentials configuration, pleaes follow https://confluence.worldline-solutions.com/display/PPSTECHNO/Using+Shared+Modules+from+GitLab+Private+Registry before attempting to use Terraf.\n" "$HOME/.terraformrc"
    fi
}

install_additional_iac_tools
install_kics_query_library
