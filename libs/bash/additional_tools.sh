#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

printf "ALERT: We should try to add this tools to the Aqua Registry. We should try to limit the number of tools installed via scripting.\n"

# TODO remove this once the node has been migrated to ECS Cluster hosting
if [[ $(cat /etc/*release) = *"Red Hat"* ]]
then
    printf "WARN: Another garbage work arounds for RHEL 7.x. on the bambora-aws Jenkins node.\n"
    export JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto/"
fi

# aws - ssm-session-manager plugin
# https://stackoverflow.com/questions/12806176/checking-for-installed-packages-and-if-not-found-install
printf "INFO: Processing AWS session-manager-plugin.\n"

# >= 0.56.0 required
if [[ -d "/usr/local/bin/session-manager-plugin" ]]
then
    printf "WARN: Removing AWS session-manager-plugin from old location.\n"
    sudo rm "/usr/local/bin/session-manager-plugin"
fi

# shellcheck disable=SC2126
if [[ $(which dnf) && $(dnf list installed | cut -f1 -d" " | grep --extended "^session-manager-plugin*" | wc -l) == 0 ]]
then
    echo "INFO: Installing AWS CLI session-manager-plugin via dnf system package manager.";
    # Fedora
    if [[ $(uname -m) == "x86_64" || $(uname -m) == "amd64" ]]
    then
        ## amd64
        # Use RPM to support `reinstall`
        sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
    elif [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
    then
        ## arm64
        # Use RPM to support `reinstall`
        sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_arm64/session-manager-plugin.rpm"
    else
        prinf "ALERT: Unable to determine CPU architecture for Fedora distro of AWS session-manager-plugin.\n"
    fi
elif [[ $(which yum) && $(yum list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) == 0 ]]
then
    # DEPRECATED 2024-03-11
    # remove on 2028-10-01
    # Use intstall_dnf()
    # RHEL
    echo "INFO: Installing AWS CLI session-manager-plugin via yum system package manager.";
    # We have to manually remove the symlink to make the pacakge install idempotent
    sudo rm "/usr/bin/session-manager-plugin" || true
    sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
elif [[ $(which apt) && $(apt list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) == 0 ]]
then
    # DEPRECATED 2024-03-11
    # remove on 2028-10-01
    # Use intstall_dnf()
    echo "INFO: Installing AWS CLI session-manager-plugin via apt system package manager.";
    if [[ $(uname -m) == "x86_64" || $(uname -m) == "amd64" ]]
    then
        ## arm64
        curl \
            --location \
            --output "session-manager-plugin.deb" \
            --show-error \
            "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb"
    elif [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
    then
        ## amd64
        curl \
            --location \
            --output "session-manager-plugin.deb" \
            --show-error \
            "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb"
    else
        prinf "ALERT: Unable to determine CPU architecture for Debian distro of AWS session-manager-plugin.\n"
    fi
    sudo dpkg -i session-manager-plugin.deb
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
    sudo mv kics-"${KICS_VER}" kics-v"${KICS_VER}"
    # Automation can target `~/.kics-installer/target_query_libs`
    ln -sfn ./kics-v"${KICS_VER}"/assets/queries/ target_query_libs
    ls -lah

    cd "${OLD_PWD}" || exit 1
fi

# -----

printf "INFO: Processing Maven.\n"
# [Maven](https://maven.apache.org/)

# >= 0.56.0 required
if [[ -d "/usr/local/bin/maven" ]]
then
    printf "WARN: Removing Maven from old location.\n"
    sudo rm -rf /usr/local/bin/maven || true
    sudo rm "/usr/local/bin/mvn" || true
fi

if [[ ! $(which mvn) || $(mvn --version) != *${MAVEN_VER}* ]]
then
    if [[ $(cat "$SESSION_SHELL") != *"/usr/bin/maven/bin"*  ]]
    then
        printf "INFO: Maven bin location not in PATH, adding...\n"
        echo "export PATH=\"/usr/bin/maven/bin:\$PATH\"" >> "${SESSION_SHELL}"
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
    sudo tar xvzf "apache-maven-${MAVEN_VER}-bin.tar.gz"
    sudo mv --force "apache-maven-${MAVEN_VER}" /usr/bin/maven
    sudo rm -rf apache*

    which mvn
    mvn --version
fi

# -----

printf "INFO: Processing SonarQube Scanner.\n"
# [SonarQube Scanner](https://docs.sonarsource.com/sonarqube/latest/)

# >= 0.56.0 required
if [[ -f "/usr/local/bin/sonar-scanner" ]]
then
    printf "WARN: Removing sonar-scanner from old location.\n"
    sudo rm -rf /usr/local/bin/sonar-scanner || true
fi

if [[ ! $(which sonar-scanner) || $(sonar-scanner --version) != *${SONARQUBE_SCANNER_VER}* ]]
then
    # sonar-scanner does not like QEMU (Linux/Unix KVM) hosts
    # https://unix.stackexchange.com/questions/89714/easy-way-to-determine-the-virtualization-technology-of-a-linux-machine
    if [[ $(sudo dmidecode -s system-product-name) == "QEMU"* ]]
    then
        printf "WARN: Running in QEMU host, sonar-scanner will not function.\n"
        # Return to the calling ./install.sh without throwing an error
        return 0
    fi

    if [[ $(cat "$SESSION_SHELL") != *"/usr/bin/sonar-scanner/bin"*  ]]
    then
        printf "INFO: sonar-scanner bin location not in PATH, adding...\n"
        echo "export PATH=\"/usr/bin/sonar-scanner/bin:\$PATH\"" >> "${SESSION_SHELL}"
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
    unzip sonar-scanner-cli-${SONARQUBE_SCANNER_VER}-linux.zip
    sudo mv --force "sonar-scanner-${SONARQUBE_SCANNER_VER}-linux" /usr/bin/sonar-scanner
    rm -rf sonar-scanner-*

    which sonar-scanner
    sonar-scanner --version
fi
