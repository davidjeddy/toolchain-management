#!/bin/bash -l

# set -exo pipefail # for debugging
set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# logic

if [[ ! $WORKSPACE ]]
then
    declare WORKSPACE
    WORKSPACE=$(git rev-parse --show-toplevel)
    export WORKSPACE
    printf "INFO: WORKSPACE %s\n" "${WORKSPACE}"
fi

## Functions

function autoUpdate() {
    printf "INFO: starting autoUpdate()\n"

    local GITLAB_HOST
    GITLAB_HOST="gitlab.kazan.myworldline.com"

    local GITLAB_PROJECT_ID
    GITLAB_PROJECT_ID="78445"

    # automation is always jenkins, credentials store provides ENV VAR values
    if [[ $(whoami) != "jenkins" ]]
    then
        # GitLab Pat token from $HOME/.terraformrc
        local GITLAB_TOKEN
        GITLAB_TOKEN=$(grep -A 1 "$GITLAB_HOST" "$HOME/.terraformrc" | sed -n '2 p' | awk '{print $3}' | jq -rM '.')
    fi

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
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --location \
        --silent \
        "https://$GITLAB_HOST/api/v4/projects/$GITLAB_PROJECT_ID/repository/tags")

    VER_IN_GL=$(echo "$VER_IN_GL" | jq -rM .[0].name)

    # Version of toolchain on Localhost via tags
    local VER_IN_LH
    cd "$WORKSPACE/.tmp/toolchain-management" || exit 1
    git fetch --tag
    VER_IN_LH=$(git describe --tags --abbrev=0)
    cd "$WORKSPACE" || exit 1

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
        exit 1
    fi
}

function exec() {
    printf "INFO: starting exec()\n"

    if [[ ! ${1} ]]
    then
        printf "ERR: Argument 1 must be list of IAC modules.\n"
        exit 1
    fi

    # Before anything else, is the branch name valid
    validateBranchName

    # Blast Radius constraints
    blastRadiusConstraintsPreventMultipleDeploymentChangeSets "${1}"

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
            # generate sbom for supply chain auditing
            generateSBOM
            # format, lint, and syntax
            iacLinting
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
            exit 1
        fi
    done
}

function documentation() {
    printf "INFO: starting documentation()\n"

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

function generateSBOM() {
    printf "INFO: starting generateSBOM()\n"

    # Because RHEL 7 + Python 3.8 have different minimal versions requirements of GLIBC
    # https://jira.techno.ingenico.com/browse/PROS-2411
    if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
    then
        printf "WARN: Running on an EOL release of Red Hat. Skipping checkov generateSBOM related invocations.\n"
        return
    fi

    # Do not generate SBOM if user is jenkins, only ensure it exists
    if [[ ! -f sbom.xml && $(whoami) == 'jenkins' ]]
    then
        printf "ERR: sbom.xml missing, failing."
        exit 1
    elif [[ -f sbom.xml && $(whoami) == 'jenkins' ]]
    then
        printf "INFO: Automation user detected, not generated sbom.xml"
        return
    fi

    {
        # Because RHEL 7 + Python 3.8 have different minimal versions requirements of GLIBC
        # https://jira.techno.ingenico.com/browse/PROS-2411
        if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
        then
            printf "WARN: Running on an EOL release of Red Hat. Skipping checkov.\n"
            return
        fi

        if [[ -f "checkov.yml" ]]; then
            # use configuration file if present. Created due to terraform/aws/worldline-gc-keycloak-dev/eu-west-1/keycloak/iohd being created BEFORE compliance was mandatory
            checkov \
                --config-file checkov.yml \
                --directory . \
                --skip-path .terraform \
                --skip-results-upload \
                -o cyclonedx \
                > "$(pwd)/sbom.xml"

        else
            checkov \
                --directory . \
                --skip-path .terraform \
                --skip-results-upload \
                -o cyclonedx \
                > "$(pwd)/sbom.xml"
        fi
        git add sbom.xml || true
    } || {
        printf "ERR: checkov SBOM failed to generate.\n"
        cat "sbom.xml"
        exit 1
    }
}

function iacCompliance() {
    printf "INFO: starting iacCompliance()\n"

    printf "INFO: checkov executing...\n"
    {
        rm -rf ".tmp/junit-checkov.xml" || exit 1
        touch ".tmp/junit-checkov.xml" || exit 1
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
        exit 1
    }

    printf "INFO: KICS executing...\n"
    {
        rm -rf ".tmp/junit-kics.xml" || exit 1
        touch ".tmp/junit-kics.xml" || exit 1

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
        exit 1
    }

    printf "INF: terraform-compliance executing...\n"
    {
        rm -rf ".tmp/junit-terraform-compliance.xml" || exit 1
        touch ".tmp/junit-terraform-compliance.xml" || exit 1

        # terraform-compliance requires a plan output in json, just do the entire IAC lifecycle to be sure
        terraform plan -no-color -out=plan.out
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
        exit 1
    }

    printf "INFO: tfsec executing...\n"
    {
        rm -rf ".tmp/junit-tfsec.xml" || exit 1
        touch ".tmp/junit-tfsec.xml" || exit 1
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
        exit 1
    }

    # trivy only scans deployment modules
    # FATAL	sbom scan ERR: scan ERR: scan failed: failed analysis: SBOM decode ERR: cyclonedx-xml scanning is not yet supported
    # if [[ -f "${WORKSPACE}/.terraform.lock.hcl" ]]
    # then
    #     printf "INFO: trivy executing...\n"
    #     {
    #         rm -rf ".tmp/junit-trivy.xml" || exit 1
    #         touch ".tmp/junit-trivy.xml" || exit 1
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
    #         exit 1
    #     }
    # fi

    # EOL scanning tool
    printf "INFO: xeol executing...\n"
    {
        rm -rf ".tmp/junit-xeol.xml" || exit 1
        touch ".tmp/junit-xeol.xml" || exit 1
        
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
        # exit 1  # TODO: restore after this issue is fixed: https://github.com/xeol-io/xeol/issues/344
    }
}

function iacLinting() {
    printf "INFO: starting iacLinting()\n"

    printf "INFO: IAC formatting.\n"
    {
        git add "$(terraform fmt -no-color .)"
    } || {
        printf "INFO: No Terraform formatting issues found, Good job!\n"
    }
    {
        git add "$(terragrunt hclfmt .)"
    } || {
        printf "INFO: No Terragrunt formatting issues found, Good job!\n"
    }

    printf "INFO: IAC linting.\n"
    {
        if [[ -f "tflint.hcl" ]]; then
            tflint \
                --config="tflint.hcl" \
                --no-module \
                --no-color \
                --format=junit \
                --ignore-module=SOURCE \
                > ".tmp/junit-tflint.xml"
        else
            tflint \
                --no-module \
                --no-color \
                --format=junit \
                --ignore-module=SOURCE \
                > ".tmp/junit-tflint.xml"
        fi
    } || {
        printf "ERR: tflint failed. Check Junit reports in .tmp\n"
        cat ".tmp/junit-tflint.xml"
        exit 1
    }
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
        exit 1
    fi
}

# Non-interactive functions

# This fn() will return EITHER an empty string (non-found) OR a string list of sorted uniq strings
function generateDiffList() {
    if [[ ! ${1} ]]
    then
        printf "ERR: Argument 1 must be command for generating a diff list.\n"
        exit 1
    fi

    local THIS_FILE_CHANGE_LIST
    # String starts with "terraform/aws/"
    # String ends with hcl OR tf
    # Checks w/ -v are ignored/removed as being valid strings
    THIS_FILE_CHANGE_LIST=$(
        eval "${1}" |
        grep "hcl\$\|tf\$" |
        grep -v .tmp/ |
        grep -v docs/ |
        grep -v examples/ |
        grep -v libs/ |
        grep -v README.md |
        grep -v sbom.xml |
        grep -v terraform.tf
    )
    if [[ ! $THIS_FILE_CHANGE_LIST ]]
    then
        printf "%s" "${THIS_FILE_CHANGE_LIST}"
    fi

    if [[ ! "$THIS_FILE_CHANGE_LIST" ]]
    then
        return
    fi

    local THIS_DIR_CHANGE_LIST
    THIS_DIR_CHANGE_LIST=$(printf "%s" "$THIS_FILE_CHANGE_LIST" | xargs -L1 dirname | sort | uniq)
    printf "%s" "${THIS_DIR_CHANGE_LIST}"
}

# Do not allow multi-account, multi-region changes in the same MR.
# This is to prevent blowing up more than on deployment at a time.
#
# IE this is a blast radius constraint
# ARG $1 STRING list of modules paths
# RETURN INT
#
function blastRadiusConstraintsPreventMultipleDeploymentChangeSets() {
    printf "INFO: starting blastRadiusConstraintsPreventMultipleDeploymentChangeSets()\n"

    if [[ ! ${1} ]]
    then
        printf "ERR: Argument 1 must be list of IAC module paths.\n"
        exit 1
    fi

    # extract the deployment path
    local DEPLOYMENT_PREFIX
    # TODO better way to extract the first 5 segments from a path?
    DEPLOYMENT_PREFIX="$(echo "${1}" | cut -d/ -f1)/$(echo "${1}" | cut -d/ -f2)/$(echo "${1}" | cut -d/ -f3)/$(echo "${1}" | cut -d/ -f4)/$(echo "${1}" | cut -d/ -f5)"

    if [[ $DEPLOYMENT_PREFIX == "././././." ]]
    then
        return 0
    fi

    printf "INFO: DEPLOYMENT_PREFIX: %s\n" "${DEPLOYMENT_PREFIX}"
    printf "INFO: DIFF_LIST: \n%s\n" "${DIFF_LIST}"
    # iterate through the entire DIFF_LIST, if any deployment path does not match we exit with error
    # https://www.baeldung.com/linux/shell-script-iterate-over-string-list
    for DEPLOYMENT_PATH in ${DIFF_LIST}
    do
        printf "INFO: DEPLOYMENT_PATH: %s\n" "${DEPLOYMENT_PATH}"
        if [[ ${DEPLOYMENT_PATH} != "${DEPLOYMENT_PREFIX}"* ]]
        then
            printf "ERR: DIFF_LIST contains the following changed deployments:\n%s\n" "${DIFF_LIST}"
            printf "ERR: We do not support cross-deployment change sets in order to limit the blast radius of any one set of changes.\n"
            printf "ERR: Please create separate branches per deployment change set.\n"
            exit 1
        fi
    done
}