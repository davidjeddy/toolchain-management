#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

function dnf_systems() {
    printf "INFO: starting dnf_systems()\n"

    # Note: We want to version pin these; but need to push everyone to the same major release of Fedora core; but this is not possible as we support every version the vendor supports
    # - this is similar to the Containerfile for wl-gc-* container based nodes
    # - this should be the primary process to control host package versions that are common in all environments
    # - use `asdf` version manager only as an alternative OR for user-space special programs
    # - this forces us to stay current with security patching as prior patch version are removed when new patches are released
    # - If listed here we should not list in a Containerfile
    sudo dnf update --assumeyes
    sudo dnf install --assumeyes \
        bash-completion \
        ca-certificates \
        curl \
        dmidecode \
        fuse-overlayfs \
        git \
        git-lfs \
        gnupg2 \
        htop \
        jq \
        libvirt-devel \
        parallel \
        pass \
        patch \
        pinentry \
        tk-devel \
        unzip \
        xz \
        xmlstarlet \
        which
}
