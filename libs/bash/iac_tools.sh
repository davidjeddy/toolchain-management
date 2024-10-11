#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# Even with KICS being installed via Aqua we still need the query libraries
printf "INFO: Processing KICS query library.\n"

# Get version of KICS being used from aqua.yaml configuration
declare KICS_VER
KICS_VER=$(grep -w "Checkmarx/kics" aqua.yaml)
KICS_VER=$(echo "$KICS_VER" | awk -F '@' '{print $2}')
KICS_VER=$(echo "$KICS_VER" | sed ':a;N;$!ba;s/\n//g')
# shellcheck disable=SC2001
KICS_VER=$(echo "$KICS_VER" | sed 's/v//g')
printf "INFO: KICS version detected: %s\n" "$KICS_VER"

if [[ ! -d ~/.kics-installer/kics-v"${KICS_VER}" ]]
then
    printf "INFO: Installing missing KICS query library into ~/.kics-installer.\n"
    printf "WARN: If the process hangs, try disablig proxy/firewalls/vpn. Golang needs the ability to download packages via ssh protocol.\n"

    # Set PWD to var for returning later
    declare OLD_PWD
    OLD_PWD="$(pwd)"

    mkdir -p ~/.kics-installer || exit 1
    cd ~/.kics-installer || exit 1

    curl \
        --location \
        --output "kics-v${KICS_VER}.tar.gz" \
        --show-error \
        "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" 
    tar -xf kics-v"${KICS_VER}".tar.gz
    # we want the dir to have the `v`
    mv kics-"${KICS_VER}" kics-v"${KICS_VER}"
    # Automation can target `~/.kics-installer/target_query_libs`
    ln -sfn ./kics-v"${KICS_VER}"/assets/queries/ target_query_libs
    ls -lah

    cd "${OLD_PWD}" || exit 1
fi
