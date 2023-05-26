#!/bin/bash -e

function doNotAllowSharedModulesInsideDeploymentProjects() {
    printf "INFO: Do not allow shared modules inside a deployment project.\n"

    #shellcheck disable=SC2002 # We do want to cat the file contents and pipeline into jq
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
    printf "INFO: generating sbom.\n"
    checkov --directory . --output cyclonedx  > sbom.xml
    git add sbom.xml || true
}

# TODO use `parallel` to execute compliance tools at the same time to reduce wait time
function terraformCompliance() {
    printf "INFO: checkov (Ignore warning about 'Failed to download module', this is due to a limitation of checkov.)...\n"
    checkov \
    --directory . \
    --download-external-modules false \
    --framework terraform \
    --quiet \
    --skip-path .tmp/ \
    --skip-path examples/ \
    --skip-path libs/

    # Temp disabled due to two bugs with terrascan
    # https://github.com/tenable/terrascan/issues/1262 and https://github.com/tenable/terrascan/issues/1266
    # printf "INFO: terrascan...\n"
    # terrascan scan --iac-type terraform --non-recursive

    printf "INFO: tfsec...\n"
    tfsec . --concise-output --exclude-downloaded-modules --no-color

    printf "INFO: kics (Takes 15 to 30 seconds, please wait)...\n"
    kics scan \
        --no-progress \
        --cloud-provider "aws" \
        --exclude-paths "*" \
        --no-color \
        --path "./" \
        --queries-path "$PROJECT_ROOT/.tmp/toolchain-management/libs/kics/assets/queries/terraform/aws" \
        --type "Terraform"
}

function terraformLinting() {
    printf "INFO: Executing Terraform Linting.\n"

    printf "INFO: Terraform/Terragrunt fmt and linting...\n"
    terraform fmt -no-color -recursive . 
    terragrunt hclfmt .
    tflint --no-color .
}
