#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

declare  GITLAB_HOST
GITLAB_HOST="gitlab.kazan.myworldline.com" # do not include protocol

declare GITLAB_PROJECT_ID
GITLAB_PROJECT_ID="78445" # Toolchain project id

## preflight

## functions

if [[ ! $WORKSPACE ]]
then
    declare WORKSPACE
    WORKSPACE=$(git rev-parse --show-toplevel)
    export WORKSPACE
    printf "INFO: WORKSPACE %s\n" "${WORKSPACE}"
fi

## Functions

### Helpers

function getGLtoken() {
    # automation is always jenkins, credentials store provides ENV VAR values
    if [[ $(whoami) != "jenkins" && -f "$HOME/.terraformrc" ]]
    then
        # GitLab Pat token from $HOME/.terraformrc
        grep -A 1 "$GITLAB_HOST" "$HOME/.terraformrc" | sed -n '2 p' | awk '{print $3}' | jq -rM '.'
    fi
}

### Logic

function autoUpdate() {
    printf "INFO: starting autoUpdate()\n"

    # Check if remote is available
    declare GL_HTTP_RES
    GL_HTTP_RES=$(curl \
        --location \
        --output /dev/null \
        --silent \
        --write-out "%{http_code}\n" \
        "https://$GITLAB_HOST")
    if [[ "$GL_HTTP_RES" != 200 ]]
    then
        printf "WARN: Unable to check remote version of Toolchain. Skipping automatic update process.\n"
        return 0
    fi

    # Version of toolchain in Gitlab via latest tag
    local VER_IN_GL
    VER_IN_GL=$(curl \
        --header "Content-Type: application/json" \
        --header "PRIVATE-TOKEN: $(getGLtoken $GITLAB_HOST)" \
        --location \
        --silent \
        "https://$GITLAB_HOST/api/v4/projects/$GITLAB_PROJECT_ID/repository/tags")

    # check if response string contains `error`
    # shellcheck disable=SC2143 # we are using `-q`
    if [[ $(echo -n "$VER_IN_GL" | grep -q "error") ]]
    then
        printf "ERROR: detected in response string:\n%s\n" "$(echo "$VER_IN_GL" | jq . -aMS)"
        return 0
    fi

    VER_IN_GL=$(echo "$VER_IN_GL" | jq -rM .[0].name)

    # Version of toolchain on Localhost via tags
    local VER_IN_LH
    cd "$WORKSPACE/.tmp/toolchain-management" || return 1
    git fetch --tag
    VER_IN_LH=$(git describe --tags --abbrev=0)
    cd "$WORKSPACE" || return 1

    # If not equal, time to update
    if [[ "$VER_IN_LH" != "$VER_IN_GL" ]]
    then
        # execute installer
        "$WORKSPACE"/libs/bash/install.sh
    fi
}

# Rebase from origin/main. If not successful do not allow pushing of the feature branch
function rebaseFromOriginMain() {
    git fetch origin main
    # Why does the different git subcommands reference remote branches differently?
    git rebase origin/main
    # shellcheck disable=SC2181
    if [[ "$?" != 0 ]]
    then
        printf "ERR: Looks like we are not able to cleanly rebase from origin/main. This would cause existing work and possible merge conflicts.\n"
        printf "ERR: Please pull origin default branch and rebase before pushing this feature branch.\n"
        return 1
    fi
}

function execute() {
    printf "INFO: starting execute()\n"

    if [[ ! ${1} ]]
    then
        printf "ERR: Argument 1 must be list of IAC modules.\n"
        return 1
    fi

    # Before anything else, is the branch name valid
    validateBranchName

    # Blast Radius constraints
    blastRadiusConstraints "$@"

    for THIS_DIR in "$@"
    do
        # Path to shared modules root is the same as WORKSPACE; in deployment project there is additional dirs to traverse
        if [[ ${WORKSPACE} == ${THIS_DIR}* ]]
        then
            printf "INFO: Changing into WORKSPACE directory if it still exists: %s\n" "${WORKSPACE}"
            cd "${WORKSPACE}"
        else
            printf "INFO: Changing into WORKSPACE/THIS_DIR directory if it still exists: %s/%s\n" "${WORKSPACE}" "${THIS_DIR}"
            cd "${WORKSPACE}"/"${THIS_DIR}" || continue
        fi

        # Create tmp dir
        createTmpDir

        # This process should only be executed during feature branch change committing
        if [[ "${0?}" == *pre-commit ]]
        then
            printf "INFO: Git pre-commit invocation detected.\n"

            # generate docs and meta-data
            documentation
            # format, lint, and syntax
            iacLinting
            # Module Version Check
            # TODO re-enable once we get time to refactor the logic
            # moduleVersionCheck
            # generate sbom for supply chain auditing
            generateSBOM
            # create a visual diagram of the resources being used in the module
            createMermaidDiagram
            # jump to the next item in "$@" list
            continue
        fi

        # Any other invocation executes the full battery of checks
        doNotAllowSharedModulesInsideDeploymentProjects

        # SAST
        iacCompliance
    done
}

# Make tmp dir to hold artifacts and reports per module
function createTmpDir() {
    printf "INFO: starting createTmpDir()\n"

    if [[ ! -d ".tmp" ]]; then
        mkdir -p ".tmp"
    fi
}

# Uses relative path, location based from exec() loop dir
function doNotAllowSharedModulesInsideDeploymentProjects() {
    printf "INFO: starting doNotAllowSharedModulesInsideDeploymentProjects()\n"

    #shellcheck disable=SC2002 # We do want to cat the file contents and pipeline into jq
    if [[ ! -f ".terraform/modules/modules.json" ]]
    then
        printf "INFO: No .terraform/modules/modules.json detected, skipping.\n"
        return
    fi

    # shellcheck disable=SC2002
    declare THIS_MODULE_SOURCES
    # shellcheck disable=SC2002
    THIS_MODULE_SOURCES=$(cat ".terraform/modules/modules.json" | jq '.Modules[] | .Source')

    for THIS_MODULE_SOURCE in ${THIS_MODULE_SOURCES}
    do
        printf "INFO: Checking module source %s\n" "${THIS_MODULE_SOURCE}"

        # https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
        if [[ "${THIS_MODULE_SOURCE}" =~ "file://"* ]]
        then
            printf "ERR: It is not allowed to use in-tree shared modules. Please use published shared modules from a supported registry.\n"
            return 1
        fi
    done
}

function documentation() {
    printf "INFO: starting documentation()\n"

    if [[ ! -f ".terraform.lock.hcl" ]]
    then
        printf "INFO: Directory is a shared module, skipping creating README.md.\n"
        return
    fi

    if [[ ! -f "README.md" ]]; then
        printf "ALERT: README.md not found in module, creating from template.\n"
        
        # Get module name and uppercase it
        declare THIS_MODULE_NAME
        THIS_MODULE_NAME=$(basename "${WORKSPACE}")
        THIS_MODULE_NAME=${THIS_MODULE_NAME^^}

        # Add markers for tf_docs to insert API documentation
        printf "# %s
        <\!-- BEGIN_TF_DOCS -->
        <\!-- END_TF_DOCS -->" "${THIS_MODULE_NAME}" | awk '{$1=$1;print}' >README.md
        sed -i 's/\\//' README.md
    fi

    # auto documentation
    printf "INFO: terraform-docs.\n"
    terraform-docs markdown table --output-file ./README.md --output-mode inject .
    git add README.md || true
}

# Generate SBOM using the syft tool; add generated sbom.xml to most recent commit via git amend
function generateSBOM() {
    printf "INFO: starting generateSBOM()\n"

    # Do not generate SBOM if user is jenkins, only ensure it exists
    if [[ ! -f sbom.xml && $(whoami) == 'jenkins' ]]
    then
        printf "ERR: sbom.xml missing, failing."
        return 1
    elif [[ -f sbom.xml && $(whoami) == 'jenkins' ]]
    then
        printf "INFO: Automation user detected, not generated sbom.xml"
        return
    fi

    # We must set TMPDIR due to error in syft + podman + linux where /tmp is to small to container the un-archived container image
    # The files are remove when the process ends, so not junk is left behind
    # https://anchorecommunity.discourse.group/t/change-the-tmpdir-that-syft-uses-when-unarchiving-a-file/265
    if [[ ! -d $HOME/.tmp ]]
    then
        mkdir -p "$HOME/.tmp"
    fi
    export TMPDIR=$HOME/.tmp

    if [[ -f Dockerfile || -f Containerfile ]]
    then
        # Container image type projects
        printf "INFO: Container image configuration detected.\n"

        if [[ ! "${TARGET}" || ! "${TARGET_VERSION_TAG}" ]]
        then
            printf "ERR: Required to provide ENV VAR \$TARGET and \$TARGET_VERSION_TAG to generate SBOM.\n"
            return 1
        fi

        syft scan \
            --scope all-layers \
            --output cyclonedx-xml=sbom.xml \
            podman:"${TARGET}":"${TARGET_VERSION_TAG}"
    else
        if [[ ! -f ".terraform.lock.hcl" ]]
        then
            printf "INFO: Directory is a shared module, not generating sbom.xml.\n"
            return
        fi

        # All other projects types (IAC)
        printf "INFO: Assuming IAC project directory.\n"
        printf "INFO: %s\n" "$(pwd)"

        syft scan \
            --output cyclonedx-xml=sbom.xml \
            dir:.
    fi

    # to working commit
    git add sbom.xml
}

function iacCompliance() {
    printf "INFO: starting iacCompliance()\n"

    if [[ ! -f ".terraform.lock.hcl" ]]
    then
        printf "INFO: Directory is a shared module, skipping compliance checks.\n"
        return
    fi

    printf "INFO: checkov executing...\n"
    {
        rm -rf ".tmp/junit-checkov.xml" || return 1
        touch ".tmp/junit-checkov.xml" || return 1
        if [[ -f "checkov.yml" ]]
        then
            printf "INFO: checkov configuration file found, using it.\n"
            checkov \
                --config-file checkov.yml \
                --directory . \
                --download-external-modules false \
                --framework terraform \
                --quiet \
                --skip-download \
                --skip-path ../ \
                --skip-path .terraform \
                -o junitxml \
                > ".tmp/junit-checkov.xml"
        else
            printf "INFO: checkov configuration NOT file found.\n"
            checkov \
                --directory . \
                --download-external-modules false \
                --framework terraform \
                --quiet \
                --skip-download \
                --skip-path ../ \
                --skip-path .terraform \
                -o junitxml \
                > ".tmp/junit-checkov.xml"
        fi
    } || {
        printf ".tmp/junit-checkov.xml\n"
        return 1
    }

    printf "INFO: KICS executing...\n"
    {
        rm -rf ".tmp/junit-kics.xml" || return 1
        touch ".tmp/junit-kics.xml" || return 1

        # find .tf and .hcl files in current folder comma separated, remove trailing comma using sed
        filesToScan=$(find . -maxdepth 1 -type f \( -name "*.tf" -o -name "*.hcl" \) -printf "%f," | sed 's/,$//')
        if [[ -f "kics.yml" ]]
        then
            printf "INFO: KICS configuration file found, using it.\n"
            # kics cli argument `--queries-path` must contain an absolute path, else a `/` gets pre-pended.
            kics scan \
                --cloud-provider "aws" \
                --config "kics.yml" \
                --no-color \
                --no-progress \
                --output-name "junit-kics" \
                --output-path ".tmp" \
                --path "$filesToScan" \
                --queries-path "$HOME/.kics/assets/queries/terraform/aws/" \
                --report-formats "junit" \
                --type "Terraform" \
                --verbose \
                --log-level info
        else
            printf "INFO: KICS configuration NOT file found.\n"
            kics scan \
                --cloud-provider "aws" \
                --no-color \
                --no-progress \
                --output-name "junit-kics" \
                --output-path ".tmp" \
                --path "$filesToScan" \
                --queries-path "$HOME/.kics/assets/queries/terraform/aws/" \
                --report-formats "junit" \
                --type "Terraform" \
                --verbose \
                --log-level info
        fi
    } || {
        printf "ERR: kics failed. Check report saved to .tmp/junit-kics.xml\n"
        cat ".tmp/junit-kics.xml"
        return 1
    }

    printf "INF: terraform-compliance executing...\n"
    {
        rm -rf ".tmp/junit-terraform-compliance.xml" || return 1
        touch ".tmp/junit-terraform-compliance.xml" || return 1

        if [[ ! -d ".terraform" ]]
        then
            printf "WARN: .terraform cache directory not found, running init.\n"
            terraform init
        fi

        # If a plan file exists, no need to re-create it
        if [[ ! -f plan.out ]]
        then
            terraform plan -no-color -out=plan.out
        fi

        terraform show -json plan.out > plan.json

        # TODO remove `--no-failure` once overrides are available
        terraform-compliance \
            --features "$HOME/.terraform-compliance/user-friendly-features/aws" \
            --no-failure \
            --planfile plan.json \
        > ".tmp/junit-terraform-compliance.xml"
    } || {
        printf "ERR: terraform-compliance failed. Check report saved to .tmp/junit-terraform-compliance.xml\n"
        cat ".tmp/junit-terraform-compliance.xml"
        return 1
    }

    printf "INFO: tfsec executing...\n"
    {
        rm -rf ".tmp/junit-tfsec.xml" || return 1
        touch ".tmp/junit-tfsec.xml" || return 1
        if [[ -f "tfsec.yml" ]]
        then
            printf "INFO: tfsec configuration file found, using it.\n"
            tfsec . \
                --concise-output \
                --config-file tfsec.yml \
                --exclude-downloaded-modules \
                --exclude-path "examples,.terra*,.tmp" \
                --format junit \
                --no-color \
                --no-module-downloads \
                > ".tmp/junit-tfsec.xml"
        else
            printf "INFO: tfsec configuration NOT file found.\n"
            tfsec . \
                --concise-output \
                --exclude-downloaded-modules \
                --exclude-path "examples,.terra*,.tmp" \
                --format junit \
                --no-color \
                --no-module-downloads \
                > ".tmp/junit-tfsec.xml"
        fi
    } || {
        printf "ERR: tfsec failed. Check report saved to .tmp/junit-tfsec.xml\n"
        cat ".tmp/junit-tfsec.xml"
        return 1
    }

    # trivy only scans deployment modules
    # FATAL	sbom scan ERR: scan ERR: scan failed: failed analysis: SBOM decode ERR: cyclonedx-xml scanning is not yet supported
    # if [[ -f "${WORKSPACE}/.terraform.lock.hcl" ]]
    # then
    #     printf "INFO: trivy executing...\n"
    #     {
    #         rm -rf ".tmp/junit-trivy.xml" || return 1
    #         touch ".tmp/junit-trivy.xml" || return 1
    #         if [[ -f "trivy.yml" ]]
    #         then
    #             # use configuration file if present.
    #             printf "INFO: trivy configuration file found, using it.\n"
    #             trivy sbom \
    #                 --config trivy.yml \
    #                 --offline-scan \
    #                 --skip-dirs .terra* \
    #                 --output junit-xml \
    #                 sbom.xml \
    #                 > ".tmp/junit-trivy.xml"
    #         else
    #             printf "INFO: trivy configuration NOT file found.\n"
    #             trivy sbom \
    #                 --offline-scan \
    #                 --skip-dirs .terra* \
    #                 --output junit-xml \
    #                 sbom.xml \
    #                 > ".tmp/junit-trivy.xml"
    #         fi
    #     } || {
    #         printf "ERR: trivy failed. Check Junit reports in .tmp\n"
    #         cat ".tmp/junit-trivy.xml"
    #         return 1
    #     }
    # fi

    # EOL scanning tool
    printf "INFO: xeol executing...\n"
    {
        rm -rf ".tmp/junit-xeol.xml" || return 1
        touch ".tmp/junit-xeol.xml" || return 1
        
        printf "INFO: xeol database update.\n"
        xeol db update
        if [[ -f "xeol.yml" ]]
        then
            printf "INFO: xeol configuration file found, using it.\n"
            xeol \
                --config xeol.yml \
                --fail-on-eol-found \
                --lookahead 6m \
                --file ".tmp/xeol.json" \
                .
        else
            printf "INFO: xeol configuration NOT file found.\n"
            xeol \
                --fail-on-eol-found \
                --lookahead 6m \
                --file ".tmp/xeol.json" \
                .
        fi
    } || {
        printf "WARN: xeol failed. Check Junit reports in .tmp\n"
        cat ".tmp/xeol.json"
        printf "WARN: failing gracefully, due to xeol problem with parsing some valid sbom.xml that miss <components><component> tags (for example ops-tooling ecs-service of deployments project)\n"
        # return 1  # TODO: restore after this issue is fixed: https://github.com/xeol-io/xeol/issues/344
    }
}

function iacLinting() {
    printf "INFO: starting iacLinting()\n"

    printf "INFO: IAC formatting.\n"
    {
        terraform fmt -no-color . && git add .
    } || {
        printf "INFO: Unable to check for Terraform formatting issues.\n"
    }
    {
        terragrunt hcl format . && git add .
    } || {
        printf "INFO: Unable to check for Terragrunt formatting issues.\n"
    }

    printf "INFO: IAC linting.\n"
    {
        if [[ -f "tflint.hcl" ]]; then
            tflint \
                --config="tflint.hcl" \
                --no-color \
                --format=junit \
                --ignore-module=SOURCE \
                > ".tmp/junit-tflint.xml"
        else
            tflint \
                --no-color \
                --format=junit \
                --ignore-module=SOURCE \
                > ".tmp/junit-tflint.xml"
        fi
    } || {
        printf "ERR: tflint failed. Check Junit reports in .tmp\n"
        cat ".tmp/junit-tflint.xml"
        return 1
    }
}

# list *.tf files changed since last commit
# grep file for "source"
# extract value path
# git::https://gitlab.kazan.myworldline.com/cicd/terraform/modules/worldline/terraform-aws-toolbox.git -> https://gitlab.kazan.myworldline.com/cicd/terraform/modules/worldline/terraform-aws-toolbox.git
# extract value ref version
# Pull latest tag
# if not match, exit ERR
function moduleVersionCheck() {
    printf "INFO: starting moduleVersionCheck()\n"

    # Always check against the previous commit what has changed.
    local DIFF_FILE_LIST
    DIFF_FILE_LIST=$(git diff HEAD~1 --name-only | grep ".tf$" | sort | uniq)
    printf "INFO: DIFF_FILE_LIST for moduleVersionCheck(): \n%s\n" "${DIFF_FILE_LIST}"

    # read per line of DIFF_FILE_LIST using \n as the delimiter
    while read -r FILE
    do
        printf "INFO: FILE: %s\n" "${FILE}"

        local FILENAME
        FILENAME=$(basename "$FILE")
        printf "INFO: FILENAME: %s\n" "${FILENAME}"

        local MODULE_SOURCE_DEFINED
        {
            MODULE_SOURCE_DEFINED=$(grep -w "source" "${FILENAME}" | grep -w "https" "${FILENAME}")
        } || {
            printf "INFO: No iac module configuration found in %s, skipping.\n" "${FILENAME}"
            continue
        }
        printf "INFO: MODULE_SOURCE_DEFINED: %s\n" "${MODULE_SOURCE_DEFINED}"

        local SOURCE_MODULE_NO_QUOTES
        # shellcheck disable=SC2001
        SOURCE_MODULE_NO_QUOTES=$(echo "${MODULE_SOURCE_DEFINED}" | sed 's/\"//g') 
        printf "INFO: SOURCE_MODULE_NO_QUOTES: %s\n" "${SOURCE_MODULE_NO_QUOTES}"

        local SOURCE_MODULE_URL
        # shellcheck disable=SC2001
        SOURCE_MODULE_URL=$(echo "${SOURCE_MODULE_NO_QUOTES}" | sed 's/^.*https/https/g') # remove everything before "https"
        printf "INFO: SOURCE_MODULE_URL: %s\n" "${SOURCE_MODULE_URL}"

        local SOURCE_MODULE_DNS_PATH
        # shellcheck disable=SC2001
        SOURCE_MODULE_DNS_PATH=$(echo "${SOURCE_MODULE_URL}" | sed 's/\.git.*$//g' ) # remove everything after ".git"
        printf "INFO: SOURCE_MODULE_DNS_PATH: %s\n" "${SOURCE_MODULE_DNS_PATH}"

        local SOURCE_MODULE_PATH
        SOURCE_MODULE_PATH=$(echo "${SOURCE_MODULE_DNS_PATH}" | sed  's/^.*com\///g' ) # remove everything after ".git"
        printf "INFO: SOURCE_MODULE_PATH: %s\n" "${SOURCE_MODULE_PATH}"

        local SOURCE_MODULE_VERSION
        # shellcheck disable=SC2001
        SOURCE_MODULE_VERSION=$(echo "${SOURCE_MODULE_URL}" | sed 's/^.*ref=//g' ) # remove everything after ".git"
        printf "INFO: SOURCE_MODULE_VERSION: %s\n" "${SOURCE_MODULE_VERSION}"

        local SOURCE_MODULE_PATH_URL_ENCODED
        SOURCE_MODULE_PATH_URL_ENCODED=$(printf %s "$SOURCE_MODULE_PATH" | jq -sRr @uri)
        printf "INFO: SOURCE_MODULE_PATH_URL_ENCODED: %s\n" "${SOURCE_MODULE_PATH_URL_ENCODED}"

        local REMOTE_PROJECT_ID
        REMOTE_PROJECT_ID=$(curl \
            --header "Content-Type: application/json" \
            --header "PRIVATE-TOKEN: $(getGLtoken $GITLAB_HOST)" \
            --location \
            --silent \
            "https://$GITLAB_HOST/api/v4/projects/$SOURCE_MODULE_PATH_URL_ENCODED" \
            | jq -rM '.id'
        )
        printf "INFO: REMOTE_PROJECT_ID: %s\n" "${REMOTE_PROJECT_ID}"

        local REMOTE_LATEST_VERSION
        REMOTE_LATEST_VERSION=$(curl \
            --header "Content-Type: application/json" \
            --header "PRIVATE-TOKEN: $(getGLtoken $GITLAB_HOST)" \
            --location \
            --silent \
            "https://$GITLAB_HOST/api/v4/projects/$REMOTE_PROJECT_ID/repository/tags" \
            | jq -rM '.[0].name'
        )
        printf "INFO: REMOTE_LATEST_VERSION: %s\n" "${REMOTE_LATEST_VERSION}"

        if [[ "$SOURCE_MODULE_VERSION" != "$REMOTE_LATEST_VERSION" ]]
        then
            printf "ERR: Module not using latest version. Must update before committing changes.\n"
            return 1
        fi
    done <<< "$DIFF_FILE_LIST"
}

function validateBranchName() {
    printf "INFO: starting validateBranchName()\n"

    local THIS_BRANCH_NAME
    THIS_BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
    if [[ $THIS_BRANCH_NAME == 'main' ]]
    then
        return
    fi

    # {action}/{ticket}/{description}
    local THIS_REGEX
    THIS_REGEX="^(add|fix|remove)\/([A-Z]{1,10})(\-)?([X0-9]{1,10})\/([A-Za-z0-9_-]){8,256}"

    if [[ ! $THIS_BRANCH_NAME =~ $THIS_REGEX ]]
    then
        printf "ERR: Branch names must align with the pattern: {action}/{ticket-id}/{description}.\n"
        printf "ERR: The RegEx pattern is as follows: %s\n" "$THIS_REGEX"
        printf "Examples:\n"
        printf "* add/ICON-37949/ecs_service_connect_updating_connect_msc7_services\n"
        printf "* remove/ICON-XXXXX/connect_msc7_internal_security_testing_resources\n"
        printf "* fix/ICON-38823/enable_resource_policy_on_efs_volumes_connect_preprod\n"
        printf "* add/ICON-38546/activegate_update_cron_task\n"
        printf "* fix/ENINC-39733/rds_instance_size_for_connect_prod\n"
        printf "* fix/INC0784730/stag_config_center_website_monitor_down.\n"
        return 1
    fi
}

# Non-interactive functions. Called from and output consumed by other functions, not for end-user usage.

# This fn() will return EITHER an empty string (no changes detected) OR a string list of sorted uniq strings
#
# ARG $1 STRING list of modules paths
# RETURN STRING list of sort, uniq paths excluding ignored expressions
#
function generateDiffList() {
    if [[ ! ${1} ]]
    then
        printf "ERR: Argument 1 must be command for generating a diff list.\n"
        return 1
    fi

    local THIS_FILE_CHANGE_LIST
    # String starts with "terraform/aws/"
    # String ends with hcl OR tf
    # Checks w/ -v are ignored/removed as being valid strings
    # "worldline-gc-cicd-build-dev/" is here to prevent execution of IAC changes in the account. It is a development account specifically for the CICD team
    THIS_FILE_CHANGE_LIST=$(
        eval "${1}" |
        grep --extended-regexp "Containerfile|Dockerfile|hcl\$|tf\$" |
        grep -v .tmp/ |
        grep -v docs/ |
        grep -v examples/ |
        grep -v libs/ |
        grep -v README.md |
        grep -v sbom.xml |
        grep -v worldline-gc-cicd-build-dev/ |
        grep -v terraform.tf

    )
    if [[ ! "$THIS_FILE_CHANGE_LIST" ]]
    then
        echo -n ""
        return 
    fi

    local THIS_DIR_CHANGE_LIST
    THIS_DIR_CHANGE_LIST=$(printf "%s" "$THIS_FILE_CHANGE_LIST" | xargs -L1 dirname | sort | uniq)
    printf "%s" "${THIS_DIR_CHANGE_LIST}"
}

# Do not allow multi-account, multi-region changes in the same MR.
# This is to prevent blowing up more than on deployment at a time.
# Max 25 paths allowed in a single MR and the depth of the paths
# must differ by only one directory. This allows a parent and its
# children to be deployed in the same MR.
#
# IE this is a blast radius constraint
# ARG $@ MULTIPLE STRINGS list of modules paths
# RETURN INT
#
function blastRadiusConstraints() {
    printf "INFO: starting blastRadiusConstraints()\n"

    if [[ ! ${1} ]]
    then
        printf "INFO: No list of modules provided to process, skipping.\n"
        return 0
    fi


    if [ $# -gt 25 ]
    then
        printf "ERR: Maximum of 25 modules allowed to be changed in a single feature branch.\n"
        return 1
    fi

    if [ "$1" == "." ]
    then
        printf "INFO: Shared module detected, skipping blast radius check.\n"
        return 0
    fi

    uniqueAccounts=$(printf "%s\n" "$@" | awk -F'/' '{print $3}' | sort | uniq)
    echo "INFO: Unique Accounts inside iac diff list: $uniqueAccounts"

    uniqueRegions=$(printf "%s\n" "$@" | awk -F'/' '{print $4}' | sort | uniq)
    echo "INFO: Unique Regions inside iac diff list: $uniqueRegions"

    if [[ "$(echo "$uniqueAccounts" | wc -l)" -gt 1 ]]; then
        echo "ERR: Cross account changes are not supported in order to limit the blast radius."
        echo "ERR: Please create separate branches per account."
        return 1
    fi

    if [[ "$(echo "$uniqueRegions" | wc -l)" -gt 1 ]]; then
        echo "ERR: Cross region changes are not supported in order to limit the blast radius."
        echo "ERR: Please create separate branches per region."
        return 1
    fi
}

# Create a Mermaid syntax visual diagram of the module and resource relationships
function createMermaidDiagram() {
    local DIAGRAM_FILENAME="mermaid_diagram.md"

    if [[ ! -f "*.tf" && ! -f "*.hcl" ]]
    then
        printf "INFO: Not in an IAC deployment module, skipping.\n"
        return 0   
    fi

    printf "INFO: starting createMermaidDiagram()\n"
    terramaid run "$(pwd)" --output "${DIAGRAM_FILENAME}"
    git add "${DIAGRAM_FILENAME}"
    return
}
