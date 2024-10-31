#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# pre-lfight

# logic

function install_java_tools() {
    printf "INFO: Processing SonarQube Scanner.\n"
    # [SonarQube Scanner](https://docs.sonarsource.com/sonarqube/latest/)

    if [[ ! $(which sonar-scanner) || $(sonar-scanner --version) != *$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)* ]]
    then
        # sonar-scanner does not like QEMU (Linux/Unix KVM) hosts
        # https://unix.stackexchange.com/questions/89714/easy-way-to-determine-the-virtualization-technology-of-a-linux-machine
        if [[ $(which sudo) ]]
        then
            # Sudo not found, assume we are in a container. If the VM is QEMU hosted, skip sonar-scanner
            if [[ $(sudo dmidecode -s system-product-name) == "QEMU"* ]]
            then
                # Do not install sonar-scanner on QEMU hosts
                printf "WARN: Running in QEMU host, sonar-scanner will not function. This is a issue with sonar-scanner, not the host.\n"
                # Return to the calling ./install.sh without throwing an error
                return 0
            fi
        fi

        # Remove existing dir if exists
        rm -rf "$HOME_USER_BIN/sonar-scanner" || true

        if [[ $(cat "$SESSION_SHELL") != *"$HOME_USER_BIN/sonar-scanner/bin"*  ]]
        then
            printf "INFO: sonar-scanner bin location not in PATH, adding...\n"
            echo "export PATH=\$HOME_USER_BIN/sonar-scanner/bin:\$PATH" >> "${SESSION_SHELL}"
            # shellcheck disable=SC1090
            source "${SESSION_SHELL}"
        fi

        curl \
            --location \
            --output "sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip" \
            --show-error \
            "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip"
        curl \
            --location \
            --output "sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip.sha256" \
            --show-error \
            "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip.sha256"

        declare CALCULATED_CHECKSUM
        CALCULATED_CHECKSUM=$(sha512sum "sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip" | awk '{print $1}')
        # shellcheck disable=SC2143
        if [[ $(grep -q "${CALCULATED_CHECKSUM}" "sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip.sha256") ]]
        then
            printf "ERR: Calculated checksum not found in provided list. Possible tampering with the archive. Aborting sonar-scanner install.\n"
            exit 1
        fi

        # Not impressed that Maven does not have a pre-compiled binary
        unzip "sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip"
        mv --force "sonar-scanner-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux" "$HOME_USER_BIN/sonar-scanner"
        rm -rf sonar-scanner-*

        which sonar-scanner
        sonar-scanner --version
    fi
}

which java
java --version

install_java_tools
