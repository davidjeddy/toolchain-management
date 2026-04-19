#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

# <= 0.73.x
function install_additional_iac_tools() {
    printf "INFO: starting install_additional_iac_tools()\n"
    printf "WARN: TODO: Add these to asdf-vm plugin library.\n"

    printf "INFO: Ensure target dir for IAC provider cache exists\n"
    mkdir -p "$HOME/.terraform.d/plugin-cache" || exit 1

    # kics
    if [[ ! $(which kics) || ! -d "$HOME/.kics/assets/queries/terraform/aws/" || $(cat "$WL_GC_TM_WORKSPACE/.kics-version") ==  "*$(kics version)*" ]]
    then
        {
            # Kics need Golang to compile
            # if golang not found OR version not the same as defined in .golang-version
            if [[ ! $(which go) || ! $(go version) =~ $(cat .golang-version) ]]
            then
                sudo dnf remove --assumeyes golang
                sudo dnf install --assumeyes "golang-0:$(cat .golang-version)"
            fi

            rm -rf "$HOME/.kics" || true

            # https://docs.kics.io/2.1.11/getting-started/#build_from_sources
            git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.kics-version)" "https://github.com/Checkmarx/kics.git" "$HOME/.kics"
            cd "$HOME/.kics" || exit 1

            # build the binary
            printf "INFO: Install kics dependencies.\n"
            go mod vendor

            printf "INFO: Building KICS binary. This can some time, please stand by.\n"
            # TODO how do we set the version when building?
            GOPROXY='https://proxy.golang.org,direct' CGO_ENABLED=0 go build \
                -a -installsuffix cgo \
                -o bin/kics cmd/console/main.go
            append_add_path "$HOME/.kics/bin" "$SESSION_SHELL"
            printf "INFO: Kics build and install completed.\n"
        } || {
            printf "ERR: kics failed to build and install.\n"
            exit 1
        }
    else
        printf "INFO: kics already installed and at the version configured in the Toolchain project.\n"
    fi

    # openinfraquote
    if [[ ! $(which oiq) || $(cat "$WL_GC_TM_WORKSPACE/.openinfraquote-version") ==  "*$(oiq --version)*" ]]
    then
        printf "INFO: openinfraquote(oiq) installation started.\n"

        # https://github.com/terrateamio/openinfraquote
        {
            local ARCH
            ARCH="amd64"
            if [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
            then
                ARCH="arm64"
            fi

            rm -rf "$HOME/.oiq" || true
            mkdir -p "$HOME/.oiq/bin"

            curl \
                --location \
                --silent \
                "https://oiq.terrateam.io/prices.csv.gz" | \
                gunzip > "$HOME/.oiq/bin/prices.csv"
            curl \
                --location \
                --silent \
                "https://github.com/terrateamio/openinfraquote/releases/download/v$(cat "$WL_GC_TM_WORKSPACE"/.openinfraquote-version)/oiq-linux-$ARCH-v$(cat "$WL_GC_TM_WORKSPACE"/.openinfraquote-version).tar.gz" \
                > "$HOME/.oiq/oiq-linux-$ARCH-v$(cat "$WL_GC_TM_WORKSPACE"/.openinfraquote-version).tar.gz"

            tar -xvzf "$HOME/.oiq/oiq-linux-$ARCH-v$(cat .openinfraquote-version).tar.gz" -C "$HOME/.oiq/bin/"
            rm "$HOME/.oiq/oiq-linux-$ARCH-v$(cat .openinfraquote-version).tar.gz"
            chmod +x "$HOME/.oiq/bin/"
            append_add_path "$HOME/.oiq/bin" "$SESSION_SHELL"

            printf "INFO: openinfraquote(oiq) install completed.\n"
        } || {
            printf "ERR: openinfraquote(oiq) failed to install or pull pricing database.\n"
            exit 1
        }
    else
        printf "INFO: openinfraquote(oiq) installed and at the version configured in the Toolchain project.\n"
    fi

    # terraform-compliance
    if [[ ! $(which terraform-compliance) || $(cat "$WL_GC_TM_WORKSPACE/.terraform-compliance-version") ==  "*$(terraform-compliance --version)*" ]]
    then
        {
            rm -rf "$HOME/.terraform-compliance" || true
            git clone https://github.com/terraform-compliance/user-friendly-features.git "$HOME/.terraform-compliance/user-friendly-features"

            pip3 install terraform-compliance=="$(cat "${WL_GC_TM_WORKSPACE}"/.terraform-compliance-version)"
            printf "INFO: terraform-compliance install completed.\n"
        } || {
            printf "ERR: terraform-compliance failed to build and install.\n"
            exit 1
        }
    else
        printf "INFO: terraform-compliance already installed and at the version configured in the Toolchain project.\n"
    fi

    # terramaid
    if [[ ! $(which terramaid) || $(cat "$WL_GC_TM_WORKSPACE/.$(cat .terramaid-version)-version") ==  "*$(terramaid version)*" ]]
    then
        printf "INFO: terramaid installation started.\n"
        mkdir -p "$HOME/.terramaid/bin"

        {
            curl \
                --location \
                --verbose \
                --output "$HOME/.terramaid/Terramaid_Linux_arm64.tar.gz" \
                "https://github.com/RoseSecurity/Terramaid/releases/download/v$(cat .terramaid-version)/Terramaid_Linux_arm64.tar.gz"
            tar -xvzf "$HOME/.terramaid/Terramaid_Linux_arm64.tar.gz" -C "$HOME/.terramaid/"

            cp -rf "$HOME/.terramaid/Terramaid" "$HOME/.terramaid/bin/terramaid"
            chmod +x "$HOME/.terramaid/bin/"
            append_add_path "$HOME/.terramaid/bin" "$SESSION_SHELL"
            rm "$HOME/.terramaid/Terramaid_Linux_arm64.tar.gz"
        } || {
            printf "ERR: terramaid failed to install.\n"
            exit 1
        }
    else
        printf "INFO: terramaid already installed and at the version configured in the Toolchain project.\n"
    fi

    # tfenv
    if [[ ! $(which tfenv) || $(cat "$WL_GC_TM_WORKSPACE/.tfenv-version") ==  "*$(tfenv --version)*" ]]
    then
        {
            rm -rf "$HOME/.tfenv" || true
            git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tfenv-version)" "https://github.com/tfutils/tfenv.git" "$HOME/.tfenv"
            append_add_path "$HOME/.tfenv/bin" "$SESSION_SHELL"
            printf "INFO: tfenv install completed.\n"

            cp -f "$WL_GC_TM_WORKSPACE/.terraform-version" "$HOME/.tfenv/.terraform-version" # ensure the default versions is set in the *env tool
        } || {
            printf "ERR: tfenv failed to build and install.\n"
            exit 1
        }
    else
        printf "INFO: tfenv already installed and at the version configured in the Toolchain project.\n"
    fi
    if [[ $(which tfenv) ]]
    then
        # shellcheck disable=SC2046
        tfenv install "$(cat "$WL_GC_TM_WORKSPACE"/.terraform-version)"
        # shellcheck disable=SC2046
        tfenv use "$(cat "$WL_GC_TM_WORKSPACE"/.terraform-version)"
    fi

    # tgenv
    if [[ ! $(which tgenv) || $(cat "$WL_GC_TM_WORKSPACE/.tgenv-version") ==  "*$(tgenv --version)*" ]]
    then
        {
            rm -rf "$HOME/.tgenv" || true
            git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tgenv-version)" "https://github.com/tgenv/tgenv.git" "$HOME/.tgenv"
            append_add_path "$HOME/.tgenv/bin" "$SESSION_SHELL"
            printf "INFO: tgenv install completed.\n"

            cp -f "$WL_GC_TM_WORKSPACE/.terragrunt-version" "$HOME/.tgenv/.terragrunt-version" # ensure the default versions is set in the *env tool
        } || {
            printf "ERR: tgenv failed to build and install.\n"
            exit 1
        }
    else
        printf "INFO: tgenv already installed and at the version configured in the Toolchain project.\n"
    fi
    if [[ $(which tgenv) ]]
    then
        # shellcheck disable=SC2046
        tgenv install "$(cat "$WL_GC_TM_WORKSPACE"/.terragrunt-version)"
        # shellcheck disable=SC2046
        tgenv use "$(cat "$WL_GC_TM_WORKSPACE"/.terragrunt-version)"
    fi

    # tofuenv
    if [[ ! $(which tofuenv) || $(cat "$WL_GC_TM_WORKSPACE/.tofuenv-version") ==  "*$(tofuenv --version)*" ]]
    then
        {
            rm -rf "$HOME/.tofuenv" || true
            git clone --depth 1 --branch "$(cat "$WL_GC_TM_WORKSPACE"/.tofuenv-version)" "https://github.com/tofuutils/tofuenv.git" "$HOME/.tofuenv"
            append_add_path "$HOME/.tofuenv/bin" "$SESSION_SHELL"
            printf "INFO: tofuenv install completed.\n"

            cp -f "$WL_GC_TM_WORKSPACE/.opentofu-version" "$HOME/.tofuenv/.opentofu-version" # ensure the default versions is set in the *env tool
        } || {
            printf "ERR: tofuenv failed to build and install.\n"
            exit 1
        }
    else
        printf "INFO: tofuenv already installed and at the version configured in the Toolchain project.\n"
    fi
    if [[ $(which tofuenv) ]]
    then
        # shellcheck disable=SC2046
        tofuenv install "$(cat "$WL_GC_TM_WORKSPACE"/.opentofu-version)"
        # shellcheck disable=SC2046
        tofuenv use "$(cat "$WL_GC_TM_WORKSPACE"/.opentofu-version)"
    fi

    # xeol
    if [[ ! $(which xeol) || $(cat "$WL_GC_TM_WORKSPACE/.xeol-version") ==  "*$(xeol --version)*" ]]
    then
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
    else
        printf "INFO: xeol already installed and at the version configured in the Toolchain project.\n"
    fi
}

# >= 0.74.x
# Stop reinventiung the wheel, use community tools insted of custom shell logic to download assets from GitHub where possible
function install_additional_iac_tools_using_dra() {
    printf "INFO: starting install_additional_iac_tools_using_dra()\n"

    # openinfraquote(oiq)
    dra download --automatic --install --tag "v$(cat "${WL_GC_TM_WORKSPACE}"/.openinfraquote-version)" terrateamio/openinfraquote
    sudo install -D -m 755 ./oiq /usr/local/bin
    rm ./oiq

    # terramaid
    dra download --automatic --install --tag "v$(cat "${WL_GC_TM_WORKSPACE}"/.terramaid-version)" RoseSecurity/Terramaid
    sudo install -D -m 755 ./Terramaid /usr/local/bin/terramaid
    rm ./Terramaid

    # tenv
    dra download --automatic --install --tag "v$(cat "${WL_GC_TM_WORKSPACE}"/.tenv-version)" tofuutils/tenv
    sudo install -D -m 755 ./tenv /usr/local/bin/tenv
    rm ./tenv

    # # tfenv - removed - aliases to `tenv tf %1`
    # if [[ -f "$HOME/.toolchainrc" && $(grep -E "tenv tf \$1" "$HOME/.toolchainrc") == "" ]]
    # then
    #     echo "function tfenv(){ tenv tf $1 }" >> "$HOME/.toolchainrc"
    # fi

    # # tgenv - removed - aliases to `tenv tg %1`
    # if [[ -f "$HOME/.toolchainrc" && $(grep -E "tenv tg \$1" "$HOME/.toolchainrc") == "" ]]
    # then
    #     echo "function tgenv(){ tenv tg $1 }" >> "$HOME/.toolchainrc"
    # fi

    # xeol
    dra download --automatic --install --tag "v$(cat "${WL_GC_TM_WORKSPACE}"/.xeol-version)" xeol-io/xeol
    sudo install -D -m 755 ./xeol /usr/local/bin/xeol
    rm ./xeol

    # install IAC tools via DRA installed tool
    tenv tf install "$(cat "$WL_GC_TM_WORKSPACE"/.terraform-version)"
    tenv tg install "$(cat "$WL_GC_TM_WORKSPACE"/.terragrunt-version)"
    tenv tofu install "$(cat "$WL_GC_TM_WORKSPACE"/.opentofu-version)"

    # Golang tools

    # Kics need Golang to compile
    # if kics and golang not found OR version not the same as defined in .golang-version
    if [[ ! $(which kics) && ( ! $(which go) || ! $(go version) =~ $(cat .golang-version) ) ]]
    then
        sudo dnf remove --assumeyes golang
        sudo dnf install --assumeyes "golang-0:$(cat .golang-version)"
    fi

    # kics
    rm -rf "$HOME/.kics" || true
    git clone \
        --branch "$(cat "$WL_GC_TM_WORKSPACE"/.kics-version)" "https://github.com/Checkmarx/kics.git" \
        --depth 1 \
        "$HOME/.kics"
    cd "$HOME/.kics" || exit 1

    # build the binary
    printf "INFO: Install kics dependencies.\n"
    go mod vendor

    printf "INFO: Building KICS binary. This can some time, please stand by.\n"
    # https://docs.kics.io/2.1.11/getting-started/#build_from_sources
    # TODO how do we set the version when building?
    GOPROXY='https://proxy.golang.org,direct' CGO_ENABLED=0 go build \
        -a -installsuffix cgo \
        -o bin/kics cmd/console/main.go
    sudo install -D -m 755 ./bin/kics /usr/local/bin/kics
    go clean -modcache

    # Python tools
    if [[ $(which pip3 ) ]]
    then
        # terraform-compliance need Python

        pip3 install terraform-compliance=="$(cat "${WL_GC_TM_WORKSPACE}"/.terraform-compliance-version)"
    fi
}
