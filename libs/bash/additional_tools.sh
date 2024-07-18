#!/bin/bash -l

set -exo pipefail

printf "ALERT: We should try to add this tools to the Aqua Registry. We should try to limit the number of tools installed via scripting.\n"

# aws - ssm-session-manager plugin
# https://stackoverflow.com/questions/12806176/checking-for-installed-packages-and-if-not-found-install
printf "INFO: Processing AWS session-manager-plugin.\n"
# shellcheck disable=SC2126
if [[ $(which dnf) && $(dnf list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
then
    echo "INFO: Installing AWS CLI session-manager-plugin via dnf system package manager.";
    # Fedora
    if [[ $(uname -m) == "x86_64" ]]
    then
        ## arm64
        sudo dnf install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
    elif [[ $(uname -m) == "aarch64" ]]
    then
        ## amd64
        sudo dnf install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_arm64/session-manager-plugin.rpm"
    else
        prinf "ALERT: Unable to determine CPU architecture for Fedora distro of AWS session-manager-plugin.\n"
    fi
elif [[ $(which yum) && $(yum list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
then
    # RHEL
    echo "INFO: Installing AWS CLI session-manager-plugin via yum system package manager.";
    # We have to manually remove the symlink to make the pacakge install idempotent
    sudo rm "/usr/local/bin/session-manager-plugin" || true
    sudo rpm -iUvh --replacepkgs "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
elif [[ $(which apt) && $(apt list installed | cut -f1 -d" " | grep --extended '^session-manager-plugin*' | wc -l) -eq 0 ]]
then
    echo "INFO: Installing AWS CLI session-manager-plugin via apt system package manager.";
    if [[ $(uname -m) == "x86_64" ]]
    then
        ## arm64
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    elif [[ $(uname -m) == "aarch64" ]]
    then
        ## amd64
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    else
        prinf "ALERT: Unable to determine CPU architecture for Debian distro of AWS session-manager-plugin.\n"
    fi
    sudo dpkg -i session-manager-plugin.deb
fi

# https://pypi.org/project/onelogin-aws-cli/
# `onelogin-aws-login` provided by package `onelogin-aws-cli`
printf "INFO: Processing OneLogin.\n"
if [[ ! $(which onelogin-aws-login) || $(onelogin-aws-login --version) != "${ONELOGIN_AWS_CLI_VER}" ]]
then
    printf "INFO: Remove old onelogin-aws-cli if it exists.\n"
    pip uninstall -y onelogin-aws-cli || true

    # We always want the latest vesrsion of tools installed via pip
    printf "INFO: Installing onelogin-aws-cli compliance tool.\n"
    pip install -U onelogin-aws-cli=="$ONELOGIN_AWS_CLI_VER"
fi

onelogin-aws-login --version
echo "onelogin-aws-cli $(pip show onelogin-aws-cli)"

# -----

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
        --silent \
        "https://github.com/Checkmarx/kics/archive/refs/tags/v${KICS_VER}.tar.gz" 
    tar -xf kics-v"${KICS_VER}".tar.gz
    # we want the dir to have the `v`
    mv kics-"${KICS_VER}" kics-v"${KICS_VER}"
    # Automation can target `~/.kics-installer/target_query_libs`
    ln -sfn ./kics-v"${KICS_VER}"/assets/queries/ target_query_libs
    ls -lah

    cd "${OLD_PWD}" || exit 1
fi

printf "INFO: Processing Maven.\n"
# [Maven](https://maven.apache.org/)
unset JAVA_HOME # Not sure why/how JAVA_HOME is being set to an incorrect value but we need to remove it for mvn to work
if [[ $(mvn --version) != *${MAVEN_VER}* ]]
then

    if [[ $(cat "$SESSION_SHELL") != *"/usr/local/bin/maven/bin"*  ]]
    then
        printf "INFO: Maven location not in PATH, adding...\n"
        echo "export PATH=\"/usr/local/bin/maven/bin:\$PATH\"" >> "${SESSION_SHELL}"
        # shellcheck disable=SC1090
        source "${SESSION_SHELL}"
    fi

    curl \
        --location \
        --output "apache-maven-${MAVEN_VER}-bin.tar.gz" \
        --show-error \
        --silent \
        "https://downloads.apache.org/maven/maven-3/${MAVEN_VER}/binaries/apache-maven-${MAVEN_VER}-bin.tar.gz"
    curl \
        --location \
        --output "apache-maven-${MAVEN_VER}-bin.tar.gz.sha512" \
        --show-error \
        --silent \
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
    sudo mv --force "apache-maven-${MAVEN_VER}" maven
    if [[ -d /usr/local/bin/maven ]]
    then
        sudo rm -rf /usr/local/bin/maven
    fi
    sudo mv --force maven /usr/local/bin
    rm -rf apache-maven-*

    which mvn
    mvn --version
fi

printf "INFO: Processing LocalStack.\n"
# [LocalStack CLI](https://github.com/localstack/localstack-cli/releases)
if [[ $(localstack --version) != "${LOCALSTACK_VER}" ]]
then
    declare ARCH
    ARCH=amd64

    if [[ $(uname -m) == "aarch64" ]]
    then
        printf "INFO: Detected ARM based system, changing ARCH value...\n"
        ARCH="arm64"
    fi

    curl \
        --location \
        --verbose \
        --output "localstack-cli-${LOCALSTACK_VER}-checksums.txt" \
        "https://github.com/localstack/localstack-cli/releases/download/v${LOCALSTACK_VER}/localstack-cli-${LOCALSTACK_VER}-checksums.txt"
    curl \
        --location \
        --verbose \
        --output "localstack-cli-${LOCALSTACK_VER}-linux-${ARCH}-onefile.tar.gz" \
        "https://github.com/localstack/localstack-cli/releases/download/v${LOCALSTACK_VER}/localstack-cli-${LOCALSTACK_VER}-linux-arm64-onefile.tar.gz"
    
    declare CALCULATED_CHECKSUM
    CALCULATED_CHECKSUM=$(sha256sum "localstack-cli-${LOCALSTACK_VER}-linux-${ARCH}-onefile.tar.gz" | awk '{print $1}')
    # shellcheck disable=SC2143
    if [[ $(grep -q "${CALCULATED_CHECKSUM}" "localstack-cli-${LOCALSTACK_VER}-checksums.txt") ]]
    then
        printf "ERR: Calculated checksum not found in provided list. Possible tampering with the archive. Aborting LocalStack install.\n"
        exit 1
    fi

    sudo tar xvzf "localstack-cli-${LOCALSTACK_VER}-linux-${ARCH}-onefile.tar.gz" -C /usr/local/bin
    rm -rf localstack-*

    which localstack
    echo "localstack $(localstack --version)"
fi
