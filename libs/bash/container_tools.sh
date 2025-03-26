#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

function install_additional_container_tools() {
    printf "INFO: starting install_additional_container_tools()\n"

    sudo dnf update --assumeyes
    sudo dnf install --assumeyes \
        podman \
        skopeo

    sudo cp /etc/containers/registries.conf /etc/containers/registries.conf."$(date +%s)".bckp || exit 1
    # allow pulling from cicd-build-prod (eu-west-1), AWS ECR Public Gallery, Quay, then Docker Hub if registry is not provided as part of the image name
    echo "[registries.search]
registries = [\"891377244928.dkr.ecr.eu-west-1.amazonaws.com\", \"public.ecr.aws\", \"quay.io\", \"docker.io\"]
short-name-mode = \"enforcing\"" | sudo tee /etc/containers/registries.conf
    cat /etc/containers/registries.conf
    
    # enable invocation of `podman` as a binary replacement for `docker` due to the jenkins-pipeline-lib requiring `docker` all over the place
    if [[ $(grep -E "alias docker" "$HOME/.bashrc") == "" ]]
    then
        echo "alias docker=/usr/bin/podman" >> .bashrc
    fi

    # Allow non-root users to execute Podman commands that require lingering shell sessions
    # Podman uses `buildah`
    # https://github.com/containers/buildah/issues/5464
    sudo loginctl enable-linger "$(id -u)"
}
