#!/bin/bash

function install_misc_tools() {

    printf "INFO: Processing MISC tools.\n"

    if [[ $(which yum) ]]
    then
        echo "WARN: Not insalling Hashicorp Packer on RHEL basd systems due to package name collision"
        return 0
    fi

    if [[ ( ! $(which packer) && "${PKR_VER}" || "$UPDATE" == "true") || "$UPDATE" == "true" ]]
    then
        printf "INFO: Installing Packer.\n"
        curl -sL --show-error "https://releases.hashicorp.com/packer/${PKR_VER}/packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip" -o "packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip"
        unzip -qq "packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip"
        sudo install packer "$BIN_DIR"
        rm -rf packer*
    fi

    # output versions - grouped based on the syntax then alphabetical of the tool name
    printf "INFO: Output Misc tool versions.\n"
    echo "packer $(packer --version)"
}
