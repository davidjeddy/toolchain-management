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
    # Note: We want to version pin these; but need to push everyone to the same major release of Fedora core; but this is not possible as we support every version the vendor supports
    # - this is similar to the Containerfile for wl-gc-* container based nodes
    # - this should be the primary process to control host package versions that are common in all environments
    # - use `asdf` version manager only as an alternative OR for user-space special programs
    # - this forces us to stay current with security patching as prior patch version are removed when new patches are released
    # - If listed here we should not list in a Containerfile
    sudo dnf update --assumeyes
    sudo dnf install --assumeyes \
        awscli2 \
        bash-completion \
        ca-certificates \
        curl \
        dmidecode \
        fuse-overlayfs \
        git \
        git-lfs \
        gnupg2 \
        golang \
        htop \
        jq \
        libvirt-devel \
        parallel \
        pass \
        patch \
        pinentry \
        podman \
        python3 \
        python3-pip \
        skopeo \
        tk-devel \
        unzip \
        xz \
        xmlstarlet \
        which \
        wget \
        yq \
        zip

    # Dunno why we have to reinstall pip every time but if this is not done the we get the `bash: pip: command not found` error
    sudo dnf reinstall --assumeyes python3-pip

    # Install if missing
    if [[ ! -f "/usr/local/bin/session-manager-plugin" ]]
    then
        printf "INFO: Installing missing AWS Session Manager Plugin via rpm.\n"
        local ARCH
        ARCH="64bit"
        if [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]
        then
            ARCH="arm64"
        fi

        curl \
            --location \
            --output "session-manager-plugin.rpm" \
            --show-error \
            "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_$ARCH/session-manager-plugin.rpm"
        sudo dnf install --assumeyes session-manager-plugin.rpm
        rm session-manager-plugin*
    fi
}

function jenkins_user_patches() {
    # Fixes problem w/ created users sessions not properly setting XDG_RUNTIME_DIR ENV VAR
    append_if "export XDG_RUNTIME_DIR=/run/user/$(id -u)" "${SESSION_SHELL}"
    
    sudo cp /etc/containers/registries.conf /etc/containers/registries.conf."$(date +%s)".bckp || exit 1
    # allow pulling from cicd-build-prod (eu-west-1), AWS ECR Public Gallery, Quay, then Docker Hub if registry is not provided as part of the image name
    echo "[registries.search]
registries = [\"891377244928.dkr.ecr.eu-west-1.amazonaws.com\", \"public.ecr.aws\", \"quay.io\", \"docker.io\"]
short-name-mode = \"enforcing\"" | sudo tee /etc/containers/registries.conf
    cat /etc/containers/registries.conf

    # enable invocation of `podman` as a binary replacement for `docker` due to the jenkins-pipeline-lib requiring `docker` all over the place
    if [[ ! -f "/usr/bin/docker" ]]
    then
        sudo ln -sfn /usr/bin/podman /usr/bin/docker
    fi

    # Allow non-root users to execute Podman commands that require lingering shell sessions
    # Podman uses `buildah`
    # https://github.com/containers/buildah/issues/5464
    sudo loginctl enable-linger "$(id -u)"
}
