#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
# shellcheck source=/home/jenkins/
source "$SHELL_PROFILE"

function install_misc_tools() {

    printf "INFO: Processing MISC tools.\n"

    if [[ $(whoami) == 'jenkins' ]]
    then
        echo "WARN: Not installing Hashicorp Packer on RHEL based Jenkins worker nodes systems due to package name collision"
        return 0
    fi

    if [[ ( ! $(which packer) && "${PKR_VER}" ) || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing Packer.\n"
        curl --location --silent --show-error "https://releases.hashicorp.com/packer/${PKR_VER}/packer_${PKR_VER}_${PLATFORM}_${ALT_ARCH}.zip" -o "packer_${PKR_VER}_${PLATFORM}_${ALT_ARCH}.zip"
        unzip -qq "packer_${PKR_VER}_${PLATFORM}_${ALT_ARCH}.zip"
        sudo install packer "$BIN_DIR"
        rm -rf packer*
    fi

    # -----

    which packer
    echo "packer $(packer --version)"
}
