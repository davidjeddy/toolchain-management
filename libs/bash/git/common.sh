#!/usr/bin/env bash

set -e

## fn()

function exec() {
    printf "INFO: starting exec()\n"

    # args

    # Use the value of $1 as source for $WORKSPACE
    # Either WORKSPACE must be set or $1 needs to be a path
    if [[ ${1} != "" ]]
    then
        WORKSPACE="${1}"
        # We DO want to export the value for other fn() to use
        export WORKSPACE
    elif [[ $WORKSPACE && ! ${1} ]]
    then
        printf "INFO: Use ENV VAR value WORKSPACE: %s\n" "$WORKSPACE"
        export WORKSPACE
    elif [[ ! $WORKSPACE && ! ${1} ]]
    then
        printf "ERR: Argument 1 or WORKSPACE must be path to root of project.\n"
        exit 1
    fi

    local CHANGE_LIST
    if [[ ! $2 ]]; then
        printf "ERR: Argument 2 must be change file list.\n"
        exit 1
    fi
    CHANGE_LIST="${2}"

    # Non loop related fn() calls
    validateBranchName

    # get a list of changed files when using only the git staged list against previouse commit
    local TF_FILES_CHANGED
    # shellcheck disable=SC2002
    TF_FILES_CHANGED=$(
        printf "%s" "${CHANGE_LIST}" |
            grep tf\$ |
            grep -v .tmp/ |
            grep -v docs/ |
            grep -v examples/ |
            grep -v libs/ |
            grep -v README.md |
            grep -v sbom.xml |
            grep -v terraform.tf ||
            true
    )
    export TF_FILES_CHANGED
    printf "INFO: TF_FILES_CHANGED value is \n%s\n" "$TF_FILES_CHANGED"

    if [[ $TF_FILES_CHANGED == "" ]]; then
        printf "INFO: TF_FILES_CHANGED is empty; no iac changes detected, exiting.\n"
        exit 0
    fi

    local MODULES_DIR
    if [[ $TF_FILES_CHANGED != "" ]]; then
        MODULES_DIR=$(echo "$TF_FILES_CHANGED" | xargs -L1 dirname | sort | uniq)
        printf "INFO: MODULES_DIR value is \n%s\n" "$MODULES_DIR"
    fi

    for DIR in $MODULES_DIR; do
        printf "INFO: Changing into %s dir if it still exists.\n" "${WORKSPACE}/${DIR}"
        cd "$WORKSPACE/$DIR" || continue

        # If a lock file exists, AND the cache directory does not, the module needs to be initilized.
        if [[ -f "terraform.lock.hcl" && ! -d "terraform" ]]; then
            terraform init -no-color
            terraform providers lock -platform=linux_amd64
        fi

        # Create tmp dir to hold artifacts and reports
        createTmpDir

        # linting and syntax formatting
        iacLinting

        # Generate sbom.xml only if the invoking scripts is pre-commit. No other time should generate sbom
        if [[ "${0?}" == *pre-commit ]]; then

            # generate docs and meta-data
            documentation

            # generate sbom for supply chain suditing
            generateSBOM
        fi

        # Finally, if the invoking script name is pre-push, also run the full compliance tooling
        if [[ "${0?}" == *pre-push ]]; then
            # Do not allow in-project shared modules
            doNotAllowSharedModulesInsideDeploymentProjects

            iacCompliance
        fi
    done
}

# Make tmp dir to hold artifacts and reports per module
function createTmpDir() {
    printf "INFO: starting createTmpDir()\n"

    if [[ ! -d ".tmp" ]]; then
        mkdir -p ".tmp"
    fi
}

function doNotAllowSharedModulesInsideDeploymentProjects() {
    printf "INFO: starting doNotAllowSharedModulesInsideDeploymentProjects()\n"

    #shellcheck disable=SC2002 # We do want to cat the file contents and pipeline into jq
    if [[ ! -f "$(pwd)/.terraform/modules/modules.json" ]]; then
        return 0
    fi

    # shellcheck disable=SC2002
    MODULE_SOURCES=$(cat "$(pwd)/.terraform/modules/modules.json" | jq '.Modules[] | .Source')

    for MODULE_SOURCE in $MODULE_SOURCES; do
        echo "INFO: Checking module source $MODULE_SOURCE"

        # https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
        if [[ "$MODULE_SOURCE" =~ "file://"* ]]; then
            echo "ERROR: It is not allowed to use shared modules placed inside a deployment project. Please use published modules from a registry."
            exit 1
        fi
    done
}

function documentation() {
    printf "INFO: starting documentation()\n"

    if [[ ! -f "README.md" ]]; then
        printf "ALERT: README.md not found in module, creating from template.\n"
        # Get module name and uppercase it
        MODULE_NAME=$(basename "${WORKSPACE}")
        MODULE_NAME=${MODULE_NAME^^}

        # Add markers for tf_docs to insert API documentation
        echo "# ${MODULE_NAME}
        <\!-- BEGIN_TF_DOCS -->
        <\!-- END_TF_DOCS -->" | awk '{$1=$1;print}' >README.md
        sed -i 's/\\//' README.md
    fi

    # auto documentation
    printf "INFO: terraform-docs.\n"
    terraform-docs markdown table --output-file ./README.md --output-mode inject .
    git add README.md || true
}

function generateSBOM() {
    printf "INFO: starting generateSBOM()\n"

    # Because RHEL 7 + Pythin 3.8 have different minimal versions requirements of GLIBC
    # https://jira.techno.ingenico.com/browse/PROS-2411
    if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
    then
        echo "WARN: Running on an EOL release of Red Hat. Skipping checkov related invokations."
        return 0
    fi

    printf "INFO: Ignore warning about 'Failed to download module', this is due to a limitation of checkov\n"
    # Do not generate SBOM if user is jenkins, onlyjust ensure it exists
    if [[ ! -f sbom.xml && $(whoami) == 'jenkins' ]]
    then
        printf "ERR: sbom.xml missing, failing."
        exit 1
    elif [[ -f sbom.xml && $(whoami) == 'jenkins' ]]
    then
        printf "INFO: Automation user detected, not generated sbom.xml"
        return 0
    fi

    {
        # Because RHEL 7 + Pythin 3.8 have different minimal versions requirements of GLIBC
        # https://jira.techno.ingenico.com/browse/PROS-2411
        if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
        then
            echo "WARN: Running on an EOL release of Red Hat. Exiting to prevent error with checkov."
            return "0"
        fi

        if [[ -f "checkov.yml" ]]; then
            # use configuration file if present. Created due to terraform/aws/worldline-gc-keycloak-dev/eu-west-1/keycloak/iohd being created BEFORE complaince was mandatory
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
        echo "ERR: checkov SBOM failed to generate."
        cat "sbom.xml"
        exit 1
    }
}

function iacCompliance() {
    printf "INFO: starting iacCompliance()\n"

    printf "INFO: checkov (Ignore warning about 'Failed to download module', this is due to a limitation of checkov)...\n"
    {
        # Because RHEL 7 + Pythin 3.8 have different minimal versions requirements of GLIBC
        # https://jira.techno.ingenico.com/browse/PROS-2411
        if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
        then
            echo "WARN: Running on an EOL release of Red Hat. Exiting to prevent error with checkov."
            return "0"
        fi

        rm -rf ".tmp/junit-checkov.xml" || exit 1
        touch ".tmp/junit-checkov.xml" || exit 1
        
        # Because RHEL 7 + Pythin 3.8 have different minimal versions requirements of GLIBC
        # https://jira.techno.ingenico.com/browse/PROS-2411
        if [[ -f "/etc/os-release" && $(cat /etc/os-release) == *"Red Hat Enterprise Linux Server 7"* ]]
        then
            echo "WARN: Running on an EOL release of Red Hat. Skipping checkov related invokations."
            echo "0"
        elif [[ -f "checkov.yml" ]]
        then
            printf "INFO: checkov configuration file found, using it.\n"
            checkov \
                --config-file checkov.yml \
                --directory . \
                --download-external-modules false \
                --framework terraform \
                --quiet \
                --skip-download \
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
                --skip-path .terraform \
                -o junitxml \
                > ".tmp/junit-checkov.xml"
        fi
    } || {
        echo "ERR: checkov failed. Check report saved to .tmp/junit-checkov.xml"
        cat ".tmp/junit-checkov.xml"
        exit 1
    }

    printf "INFO: KICS executing...\n"
    {
        rm -rf ".tmp/junit-kics.xml" || exit 1
        touch ".tmp/junit-kics.xml" || exit 1

        # find .tf and .hcl files in current folder comma separated, remove trailing comma using sed
        filesToScan=$(find . -maxdepth 1 -type f \( -name "*.tf" -o -name "*.hcl" \) -printf "%f," | sed 's/,$//')
        if [[ -f "kics.yml" ]]; then
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
                --queries-path ~/.kics-installer/target_query_libs/terraform/aws/ \
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
                --queries-path ~/.kics-installer/target_query_libs/terraform/aws/ \
                --report-formats "junit" \
                --type "Terraform" \
                --verbose \
                --log-level info
        fi
    } || {
        echo "ERR: kics failed. Check report saved to .tmp/junit-kics.xml"
        cat ".tmp/junit-kics.xml"
        exit 1
    }

    printf "INFO: tfsec executing...\n"
    {
        rm -rf ".tmp/junit-tfsec.xml" || exit 1
        touch ".tmp/junit-tfsec.xml" || exit 1
        if [[ -f "tfsec.yml" ]]; then
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
        echo "ERR: tfsec failed. Check report saved to .tmp/junit-tfsec.xml"
        cat ".tmp/junit-tfsec.xml"
        exit 1
    }

    # trivy only scans deployment modules
    # FATAL	sbom scan error: scan error: scan failed: failed analysis: SBOM decode error: cyclonedx-xml scanning is not yet supported
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
    #         echo "ERR: trivy failed. Check Junit reports in .tmp"
    #         cat ".tmp/junit-trivy.xml"
    #         exit 1
    #     }
    # fi

    # EOL scanning tool
    printf "INFO: xeol executing...\n"
    {
        rm -rf ".tmp/junit-xeol.xml" || exit 1
        touch ".tmp/junit-xeol.xml" || exit 1
        if [[ -f "xeol.yml" ]]
        then
            # use configuration file if present.
            printf "INFO: xeol configuration file found, using it.\n"
            xeol \
                --config xeol.yml \
                --fail-on-eol-found \
                --lookahead 1m \
                sbom.xml
        else
            printf "INFO: xeol configuration NOT file found.\n"
            xeol \
                --fail-on-eol-found \
                --lookahead 1m \
                sbom.xml
        fi
    } || {
        echo "WARN: xeol failed. Check Junit reports in .tmp"
        echo "WARN: failing gracefully, due to xeol problem with parsing some valid sbom.xml that miss <components><component> tags (for example ops-tooling ecs-service of deployments project)"
        cat ".tmp/junit-xeol.xml"
        # exit 1  # TODO: restore after this issue is fixed: https://github.com/xeol-io/xeol/issues/344
    }
}

function iacLinting() {
    printf "INFO: starting iacLinting()\n"

    terraform fmt -no-color -recursive .
    terragrunt hclfmt .

    printf "INFO: tflint executing...\n"
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
        echo "ERR: tflint failed. Check Junit reports in .tmp"
        cat ".tmp/junit-tflint.xml"
        exit 1
    }
}

function validateBranchName() {
    printf "INFO: starting validateBranchName()\n"

    local BRANCH_NAME
    BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"

    # {action}/{ticket}/{description}
    local REGEX
    REGEX="^(add|fix|remove)\/([A-Z]{1,10})(\-)?([X0-9]{1,10})\/([a-z0-9_]){8,256}"

    if [[ ! $BRANCH_NAME =~ $REGEX && $BRANCH_NAME != 'main' && $BRANCH_NAME != 'master' ]]
    then
        printf "ERR: Branch names must align with the pattern: {action}/{ticket-id}/{description}.\n"
        printf "ERR: The RegEx pattern is as follows: %s\n" "$REGEX"
        printf "Examples:\n"
        printf "* add/ICON-37949/ecs_service_connect_updating_connect_msc7_services\n"
        printf "* remove/ICON-XXXXX/connect_msc7_internal_security_testing_resources\n"
        printf "* fix/ICON-38823/enable_resource_policy_on_efs_volumes_connect_preprod\n"
        printf "* add/ICON-38546/activegate_update_cron_task\n"
        printf "* fix/ENINC-39733/rds_instance_size_for_connect_prod\n"
        printf "* fix/INC0784730/stag_config_center_website_monitor_downga.\n"
        exit 1
    fi
}
