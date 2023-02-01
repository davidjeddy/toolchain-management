#!/bin/bash

# usage install_misc_tools
function install_misc_tools() {

    printf "INFO: Processing MISC tools.\n"

    if [[ (! $(which packer) && "${PACKER_VER}" || "${UPDATE}" == "true") || "${UPDATE}" == "true" ]]
    then
        printf "INFO: Installing Packer.\n"
        curl -L "https://releases.hashicorp.com/packer/${PKR_VER}/packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip" -o "packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip"
        unzip "packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip"
        sudo install packer /usr/local/bin
        rm -rf packer*
    fi

    # output versions - grouped based on the syntax then alphabetical of the tool name
    printf "INFO: Output Misc tool versions.\n"
    echo "packer $(packer --version)"
}
