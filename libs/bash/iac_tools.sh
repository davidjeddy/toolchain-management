#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

function install_additional_iac_tools() {
    printf "INFO: starting install_additional_tools()\n"

    printf "INFO: Ensure target dir for IAC provider cache exists\n"
    mkdir -p "$HOME/.terraform.d/plugin-cache" || exit 1

    # kics
    {
        # Kics need Golang to compile
        if [[ ! $(which go) ]]
        then
            sudo dnf update --assumeyes
            sudo dnf install --assumeyes "golang-$(cat .golang-version)"
        fi

        rm -rf "$HOME/.kics" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.kics-version)" "https://github.com/Checkmarx/kics.git" "$HOME/.kics"
        cd "$HOME/.kics" || exit 1

        # build the binary
        printf "INFO: Install kics dependencies.\n"
        go mod vendor

        printf "INFO: Building KICS binary. This can some time, please stand by.\n"
        GOPROXY='https://proxy.golang.org,direct' CGO_ENABLED=0 go build \
            -a -installsuffix cgo \
            -o bin/kics cmd/console/main.go
        append_add_path "$HOME/.kics/bin" "$SESSION_SHELL"
        printf "INFO: Kics build and install completed.\n"
    } || {
        printf "ERR: kics failed to build and install.\n"
        exit 1
    }

    # terraform-compliance
    {
        rm -f "$HOME/.terraform-compliance" || true
        git clone https://github.com/terraform-compliance/user-friendly-features.git "$HOME/.terraform-compliance/user-friendly-features"

        pip3 install terraform-compliance=="$(cat "${WL_GC_TM_WORKSPACE}"/.terraform-compliance-version)"
        printf "INFO: terraform-compliance install completed.\n"
    } || {
        printf "ERR: terraform-compliance failed to build and install.\n"
        exit 1
    }

    # tfenv
    {
        rm -rf "$HOME/.tfenv" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tfsec-version)" "https://github.com/tfutils/tfenv.git" "$HOME/.tfenv"
        append_add_path "$HOME/.tfenv/bin" "$SESSION_SHELL"
        printf "INFO: tfenv install completed.\n"
        # shellcheck disable=SC2046
        tfenv install "$(cat "$WL_GC_TM_WORKSPACE"/.terraform-version)"

        # shellcheck disable=SC2046
        tfenv use "$(cat "$WL_GC_TM_WORKSPACE"/.terraform-version)"
        cp -f "$WL_GC_TM_WORKSPACE/.terraform-version" "$HOME/.tfenv/.terraform-version" # ensure the default versions is set in the *env tool
    } || {
        printf "ERR: tfenv failed to build and install.\n"
        exit 1
    }

    # tgenv
    {
        rm -rf "$HOME/.tgenv" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tgenv-version)" "https://github.com/tgenv/tgenv.git" "$HOME/.tgenv"
        append_add_path "$HOME/.tgenv/bin" "$SESSION_SHELL"
        printf "INFO: tgenv install completed.\n"

        # shellcheck disable=SC2046
        tgenv install "$(cat "$WL_GC_TM_WORKSPACE"/.terragrunt-version)"

        # shellcheck disable=SC2046
        tgenv use "$(cat "$WL_GC_TM_WORKSPACE"/.terragrunt-version)"
        cp -f "$WL_GC_TM_WORKSPACE/.terragrunt-version" "$HOME/.tgenv/.terragrunt-version" # ensure the default versions is set in the *env tool
    } || {
        printf "ERR: tgenv failed to build and install.\n"
        exit 1
    }

    # tofuenv
    {
        rm -rf "$HOME/.tofuenv" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tofuenv-version)" "https://github.com/tofuutils/tofuenv.git" "$HOME/.tofuenv"
        append_add_path "$HOME/.tofuenv/bin" "$SESSION_SHELL"
        printf "INFO: tofuenv install completed.\n"

        # shellcheck disable=SC2046
        tofuenv install "$(cat "$WL_GC_TM_WORKSPACE"/.opentofu-version)"

        # shellcheck disable=SC2046
        tofuenv use "$(cat "$WL_GC_TM_WORKSPACE"/.opentofu-version)"
        cp -f "$WL_GC_TM_WORKSPACE/.opentofu-version" "$HOME/.tofuenv/.opentofu-version" # ensure the default versions is set in the *env tool
    } || {
        printf "ERR: tofuenv failed to build and install.\n"
        exit 1
    }

    # xeol
    {
        rm -rf "$HOME/.xeol" || true
        git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.xeol-version)" "https://github.com/xeol-io/xeol.git" "$HOME/.xeol"
        cd "$HOME/.xeol" || exit
        ./install.sh

        append_add_path "$HOME/.xeol/bin" "$SESSION_SHELL"
        printf "INFO: xeol install completed.\n"
    } || {
        printf "ERR: xeol failed to build and install.\n"
        exit 1
    }
}
