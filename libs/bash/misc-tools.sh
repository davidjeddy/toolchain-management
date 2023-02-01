#!/bin/bash

# General Tools

PKR_VER="1.8.1"

# usage install_misc_tools
function install_misc_tools() {

    if [[ ! $(which packer) && "${PACKER_VER}" ]]
    then
        printf "INFO: Installing Packer.\n"
        curl -L "https://releases.hashicorp.com/packer/${PKR_VER}/packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip" -o "packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip"
        unzip "packer_${PKR_VER}_${PLATFORM}_${ARCH}.zip"
        sudo install packer /usr/local/bin
        rm -rf packer*
    fi

    # output versions - grouped based on the syntax/alphabetical of the tool name
    printf "INFO: Output tool version.\n"
    echo "packer $(packer --version)"
}
