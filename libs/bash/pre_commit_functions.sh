#!/bin/bash -e

# TODO use `parallel` to execute functions at the same time to reduce wait time
# TODO use tool configuration file if present should not require an if/then eval

# Make tmp dir to hold artifacts and reports per module
function createTmpDir() {
    if [[ ! -d ".tmp" ]]
    then
        mkdir -p ".tmp"
    fi
}

function doNotAllowSharedModulesInsideDeploymentProjects() {
    printf "INFO: Do not allow shared modules inside a deployment project.\n"

    #shellcheck disable=SC2002 # We do want to cat the file contents and pipeline into jq
    if [[ ! -f ".terraform/modules/modules.json" ]]
    then
        return 0
    fi

    # shellcheck disable=SC2002
    MODULES_IN_USE=$(cat ".terraform/modules/modules.json" | jq '.Modules[] | .Source')

    for MODULE in $MODULES_IN_USE
    do
        # https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
        if [[ "$PROJECT_ROOT" == *"$MODULE"* ]]; then
            echo "ERROR: It is not allowed to use shared modules placed inside a deployment project. Please use shared modules from a registry."
            exit 1
        fi
    done
}

function documentation() {
    printf "INFO: documentation.\n"
    if [[ ! -f "./README.md" ]]
    then
        printf "ALERT: README.md not found in module, creating from template.\n"
        # Get module name and uppercase it
        #shellcheck disable=SC2046 # Not sure why shellcheck complains about this
        MODULE_NAME=$(basename $(pwd))
        MODULE_NAME=${MODULE_NAME^^}
        
        # Add markers for tf_docs to insert API documentation
        echo "# ${MODULE_NAME}
        <\!-- BEGIN_TF_DOCS -->
        <\!-- END_TF_DOCS -->" | awk '{$1=$1;print}' > README.md
        sed -i 's/\\//' README.md
    fi

    # auto documentation
    printf "INFO: terraform-docs.\n"
    terraform-docs markdown table --output-file ./README.md --output-mode inject .

    printf "INFO: Adding updated README to Git staged files.\n"
    git add README.md || true
}

function generateSBOM() {
    printf "INFO: generating sbom using checkov (Ignore warning about 'Failed to download module', this is due to a limitation of checkov.)...\n"
    {
        if [[ -f "checkov.yml" ]]
        then
            # use configuration file if present. Created due to terraform/deployments/terraform/aws/worldline-gc-keycloak-dev/eu-west-1/keycloak/iohd being created BEFORE complaince was mandatory    
            checkov \
                --config-file checkov.yml \
                --directory . \
                --output cyclonedx \
                > sbom.xml
        else
            checkov \
                --directory . \
                --output cyclonedx \
                > sbom.xml
        fi
        git add sbom.xml || true
    } || {
        echo "ERR: checkov SBOM failed to generate."
        exit 1
    }
}

function terraformCompliance() {
    printf "INFO: checkov (Ignore warning about 'Failed to download module', this is due to a limitation of checkov.)...\n"
    {
        if [[ -f "checkov.yml" ]]
        then
            # use configuration file if present.
            checkov \
                --config-file checkov.yml \
                --directory . \
                --download-external-modules false \
                --framework terraform \
                --output junitxml \
                --quiet \
                --skip-path .terra*/ \
                --skip-path .tmp/ \
                --skip-path examples/ \
                --skip-path libs/ \
                > "$(pwd)/.tmp/junit-checkov.xml"
        else
            # 'normal' full scan
            checkov \
                --directory . \
                --download-external-modules false \
                --framework terraform \
                --quiet \
                --skip-path .terra*/ \
                --skip-path .tmp/ \
                --skip-path examples/ \
                --output junitxml \
                --skip-path libs/ \
                > "$(pwd)/.tmp/junit-checkov.xml"
        fi
    } || {
        echo "ERR: checkov failed. Check report saved to $(pwd)/.tmp/junit-checkov.xml"
        exit 1
    }

    # # Temp disabled due to not yet supporting TF_TOKEN_* auth source
    # # https://github.com/tenable/terrascan/issues/1566
    # # Also having problems with using GitLab PAT in Jenkins
    # printf "INFO: terrascan...\n"
    # {
    #     if [[ -f "terrascan.toml" ]]
    #     then
    #         # use configuration file if present.
    #         terrascan scan \
    #             --config-path terrascan.tml \
    #             --iac-type terraform \
    #             --log-level error \
    #             --non-recursive \
    #             --output junit-xml \
    #             --use-colors f \
    #             > .tmp/junit-terrascan.xml
    #     else
    #         terrascan scan \
    #             --iac-type terraform \
    #             --log-level error \
    #             --non-recursive \
    #             --output junit-xml \
    #             --use-colors f \
    #             > .tmp/junit-terrascan.xml
    #     fi
    # } || {
    #     echo "ERR: terrascan failed. Check Junit reports in .tmp"
    #     exit 1
    # }

    {
        if [[ -f "tfsec.yml" ]]
        then
            # use configuration file if present.
            tfsec . \
                --concise-output \
                --config-file tfsec.yml \
                --exclude-downloaded-modules \
                --exclude-path "examples,.terra*,.tmp" \
                --format junit \
                --no-color \
                --no-module-downloads \
                > "$(pwd)/.tmp/junit-tfsec.xml"                
        else
            tfsec . \
                --concise-output \
                --exclude-downloaded-modules \
                --exclude-path "examples,.terra*,.tmp" \
                --format junit \
                --no-color \
                --no-module-downloads \
                > "$(pwd)/.tmp/junit-tfsec.xml"
        fi
    } || {
        echo "ERR: tfsec failed. Check report saved to $(pwd)/.tmp/junit-tfsec.xml"
        exit 1
    }

    {
        printf "INFO: kics (Takes 15 to 30 seconds, please wait)...\n"
        
        declare KICS_IGNORE_RULE_IDS
        if [[ ! -f ".terraform.lock.hcl" && ! -d ".terraform" ]]
        then
            # if shared module, add ignore rules
            export KICS_IGNORE_RULE_IDS="e38a8e0a-b88b-4902-b3fe-b0fcb17d5c10"
        fi

        # use configuration file if present.
        if [[ -f "kics.yml" ]]
        then
            kics scan \
                --cloud-provider "aws" \
                --config "kics.yml" \
                --exclude-paths "*" \
                --exclude-queries "$KICS_IGNORE_RULE_IDS" \
                --no-color \
                --no-progress \
                --output-name "junit-kics" \
                --output-path "$(pwd)/.tmp" \
                --path "./" \
                --queries-path "$PROJECT_ROOT/.tmp/toolchain-management/libs/kics/assets/queries/terraform/aws" \
                --report-formats "junit" \
                --type "Terraform"
        else
            kics scan \
                --cloud-provider "aws" \
                --exclude-paths "*" \
                --exclude-queries "$KICS_IGNORE_RULE_IDS" \
                --no-color \
                --no-progress \
                --output-name "junit-kics" \
                --output-path "$(pwd)/.tmp" \
                --path "./" \
                --queries-path "$PROJECT_ROOT/.tmp/toolchain-management/libs/kics/assets/queries/terraform/aws" \
                --report-formats "junit" \
                --type "Terraform"
        fi
    } || {
        echo "ERR: kics failed. Check report saved to $(pwd)/.tmp/junit-kics.xml"
        exit 1
    }
}

function terraformLinting() {
    printf "INFO: Executing Terraform Linting.\n"

    printf "INFO: Terraform/Terragrunt fmt and linting...\n"
    terraform fmt -no-color -recursive . 
    terragrunt hclfmt .
    tflint --chdir="$(pwd)" --fix --module --no-color
}
