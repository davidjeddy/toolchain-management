#!/bin/false

# preflight

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# configuration

# functions

function install_java_tools() {
    printf "INFO: Processing SonarQube Scanner.\n"
    # [SonarQube Scanner](https://docs.sonarsource.com/sonarqube/latest/)

    if [[ ! -f "/lib64/ld-linux-x86-64.so.2" ]]
    then
        printf "WARN: QEMU based host detected based on missing %s, skipping sonar-scanner install.\n" "/lib64/ld-linux-x86-64.so.2"
        return 0
    fi
    
    if [[ ! $(which sonar-scanner) || $(sonar-scanner --version) != *$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)* ]]
    then
        # Remove existing dir if exists
        rm -rf "$HOME_USER_BIN/sonar-scanner" || true

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

        # Not impressed that sonar-scanner does not have a pre-compiled binary
        unzip "sonar-scanner-cli-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux.zip"
        mv --force "sonar-scanner-$(cat "$WL_GC_TM_WORKSPACE"/.sonarqube-scanner-version)-linux" "$HOME_USER_BIN/sonar-scanner"
        rm -rf sonar-scanner-*
        append_add_path "$HOME_USER_BIN/sonar-scanner/bin" "$SESSION_SHELL"
        
        # shellcheck disable=SC1090
        source "$SESSION_SHELL" || exit 

        which sonar-scanner
        sonar-scanner --version
    fi
}
