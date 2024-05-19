#!/usr/bin/env bash

set -e

printf "INFO: Starting publis_iac_module_version.\n"

if [[ ! "${1}" ]]
then
    printf "ERR: Project host must be provided.\n"
    exit 1
fi
declare PROJECT_HOST
PROJECT_HOST="${1}"

if [[ ! "${2}" ]]
then
    printf "ERR: Project id must be provided.\n"
    exit 1
fi
declare PROJECT_ID
PROJECT_ID="${2}"

if [[ ! "${3}" ]]
then
    printf "ERR: Project name must be provided.\n"
    exit 1
fi
declare PROJECT_NAME
PROJECT_NAME="${3}"

if [[ ! $GITLAB_CREDENTIALSID ]]
then
    printf "ERR: Required ENV VAR GITLAB_CREDENTIALSID not set.\n"
    exit 1
fi

declare LOV
declare TAG

TAG="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
printf "INFO: TAG: %s\n" "$TAG"

# List Of Versions
# https://forum.gitlab.com/t/listing-all-terraform-modules-published-under-group-via-api/75045
LOV=$(
    curl \
        --header "Authorization: Bearer ${GITLAB_CREDENTIALSID}" \
        --insecure \
        --location \
        --silent \
        "https://${PROJECT_HOST}/api/v4/projects/${PROJECT_ID}/packages?package_type=terraform_module" \
        | jq -r .[].version
)
printf "INFO: LOV: %s\n" "$LOV"

# If TAG value does not exists in the List of Versions, create and publish to GitLab
# https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
if [[ "$LOV" != *"$TAG"* ]]
then
    rm "${WORKSPACE}/.tmp/${PROJECT_NAME}-$TAG.tgz" || true
    tar \
        --create \
        --directory . \
        --exclude=.git \
        --exclude=.tmp \
        --exclude=.tgz \
        --file "${WORKSPACE}/.tmp/${PROJECT_NAME}-$TAG.tgz" \
        --gzip \
        .

    curl \
        --header "PRIVATE-TOKEN: ${GITLAB_CREDENTIALSID}" \
        --insecure \
        --location \
        --upload-file "${WORKSPACE}/.tmp/${PROJECT_NAME}-$TAG.tgz" \
        --url "https://${PROJECT_HOST}/api/v4/projects/${PROJECT_ID}/packages/terraform/modules/${PROJECT_NAME}/aws/$TAG/file"
fi

printf "INFO: ...done.\n"
