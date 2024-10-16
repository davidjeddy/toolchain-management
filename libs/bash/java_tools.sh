#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
source "$SESSION_SHELL" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

function install_java_tools() {
    printf "INFO: Processing Java Tools.\n"
    # [Maven](https://maven.apache.org/)

    if [[ ! $(which mvn) || $(mvn --version) != *${MAVEN_VER}* ]]
    then
        if [[ $(cat "$SESSION_SHELL") != *"$HOME_USER_BIN/maven/bin"* ]]
        then
            printf "INFO: Maven bin location not in PATH, adding...\n"
            echo "export PATH=\"$HOME_USER_BIN/maven/bin:\$PATH\"" >> "${SESSION_SHELL}"
            # shellcheck disable=SC1090
            source "${SESSION_SHELL}"
        fi

        curl \
            --location \
            --output "apache-maven-${MAVEN_VER}-bin.tar.gz" \
            --show-error \
            "https://downloads.apache.org/maven/maven-3/${MAVEN_VER}/binaries/apache-maven-${MAVEN_VER}-bin.tar.gz"
        curl \
            --location \
            --output "apache-maven-${MAVEN_VER}-bin.tar.gz.sha512" \
            --show-error \
            "https://downloads.apache.org/maven/maven-3/${MAVEN_VER}/binaries/apache-maven-${MAVEN_VER}-bin.tar.gz.sha512"

        declare CALCULATED_CHECKSUM
        CALCULATED_CHECKSUM=$(sha512sum "apache-maven-${MAVEN_VER}-bin.tar.gz" | awk '{print $1}')
        # shellcheck disable=SC2143
        if [[ $(grep -q "${CALCULATED_CHECKSUM}" "apache-maven-${MAVEN_VER}-bin.tar.gz.sha512") ]]
        then
            printf "ERR: Calculated checksum not found in provided list. Possible tampering with the archive. Aborting Maven install.\n"
            exit 1
        fi

        # Not impressed that Maven does not have a pre-compiled binary
        tar xvzf "apache-maven-${MAVEN_VER}-bin.tar.gz"
        mv --force "apache-maven-${MAVEN_VER}" "$HOME_USER_BIN/maven"
        rm -rf apache*

        which mvn
        mvn --version
    fi

    # -----

    printf "INFO: Processing SonarQube Scanner.\n"
    # [SonarQube Scanner](https://docs.sonarsource.com/sonarqube/latest/)

    if [[ ! $(which sonar-scanner) || $(sonar-scanner --version) != *${SONARQUBE_SCANNER_VER}* ]]
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

        if [[ $(cat "$SESSION_SHELL") != *"$HOME_USER_BIN/sonar-scanner/bin"*  ]]
        then
            printf "INFO: sonar-scanner bin location not in PATH, adding...\n"
            echo "export PATH=\"$HOME_USER_BIN/sonar-scanner/bin:\$PATH\"" >> "${SESSION_SHELL}"
            # shellcheck disable=SC1090
            source "${SESSION_SHELL}"
        fi

        curl \
            --location \
            --output "sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip" \
            --show-error \
            "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip"
        curl \
            --location \
            --output "sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip.sha256" \
            --show-error \
            "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip.sha256"

        declare CALCULATED_CHECKSUM
        CALCULATED_CHECKSUM=$(sha512sum "sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip" | awk '{print $1}')
        # shellcheck disable=SC2143
        if [[ $(grep -q "${CALCULATED_CHECKSUM}" "sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip.sha256") ]]
        then
            printf "ERR: Calculated checksum not found in provided list. Possible tampering with the archive. Aborting sonar-scanner install.\n"
            exit 1
        fi

        # Not impressed that Maven does not have a pre-compiled binary
        unzip "sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip"
        mv --force "sonar-scanner-${SONARQUBE_SCANNER_VER}-linux" "$HOME_USER_BIN/sonar-scanner"
        rm -rf sonar-scanner-*

        which sonar-scanner
        sonar-scanner --version
    fi
}

install_java_tools
