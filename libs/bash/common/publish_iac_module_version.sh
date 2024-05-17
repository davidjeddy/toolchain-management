#!/usr/bin/env bash

set -e

declare TAG
declare LOV

TAG="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
echo "TAG: $TAG"

# List Of Versions
# https://forum.gitlab.com/t/listing-all-terraform-modules-published-under-group-via-api/75045
LOV=$(
    curl \
        --header "Authorization: Bearer ''' +  env.gitlabPAT + '''" \
        --insecure \
        --location \
        --silent \
        "https://'''+gitlabHost+'''/api/v4/projects/''' + gitlabProjectId + '''/packages?package_type=terraform_module" \
        | jq -r .[].version
)

# If TAG value does not exists in the List of Versions, create and publish to GitLab
# https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
if [[ "$LOV" != *"$TAG"* ]]
then
    rm "${WORKSPACE}/.tmp/'''+gitlabProjectName+'''-$TAG.tgz" || true
    tar \
        --create \
        --directory . \
        --exclude=.git \
        --exclude=.tmp \
        --exclude=.tgz \
        --file "${WORKSPACE}/.tmp/'''+gitlabProjectName+'''-$TAG.tgz" \
        --gzip \
        .

    curl \
        --header "PRIVATE-TOKEN: ''' +  env.gitlabPAT + '''" \
        --insecure \
        --location \
        --upload-file "${WORKSPACE}/.tmp/'''+gitlabProjectName+'''-$TAG.tgz" \
        --url "https://'''+gitlabHost+'''/api/v4/projects/''' + gitlabProjectId + '''/packages/terraform/modules/'''+gitlabProjectName+'''/aws/$TAG/file"
fi
