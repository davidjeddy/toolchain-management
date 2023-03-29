#!/bin/bash -e

## functions

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
    checkov --directory . --framework terraform --skip-path ./libs --quiet

    # Temp disabled due to two bugs with terrascan
    # https://github.com/tenable/terrascan/issues/1262 and https://github.com/tenable/terrascan/issues/1266
    # printf "INFO: terrascan...\n"
    # terrascan scan --iac-type terraform --non-recursive

    printf "INFO: tfsec...\n"
    tfsec . --concise-output --exclude-downloaded-modules --no-color

    if [[ "$PROJECT_ROOT" == *"terraform/aws" ]]
    then
        printf "INFO: kics (Takes 15 to 30 seconds, please wait)...\n"
        kics scan \
            --cloud-provider "aws" \
            --exclude-paths "./*/*" \
            --minimal-ui \
            --no-color \
            --path "./" \
            --queries-path "$PROJECT_ROOT/libs/kics/assets/queries/terraform/aws" \
            --type "Terraform"
    fi
}

function terraformLinting() {
    printf "INFO: Executing Terraform Linting.\n"

    printf "INFO: Terraform/Terragrunt fmt and linting...\n"
    terraform fmt -no-color -recursive . 
    terragrunt hclfmt .
    tflint --no-color .
}

## vars

declare ORIG_PWD
ORIG_PWD="$(pwd)"
printf "INFO: ORIG_PWD value is \n%s\n" "$ORIG_PWD"

declare PROJECT_ROOT
PROJECT_ROOT=$(git rev-parse --show-toplevel)
printf "INFO: PROJECT_ROOT value is \n%s\n" "$PROJECT_ROOT"

declare TF_FILES_CHANGED
# get a list of changed files when using only the git staged list against previouse commit
TF_FILES_CHANGED=$(git diff --name-only --staged HEAD~1 | grep tf$ || true)
printf "INFO: TF_FILES_CHANGED value is \n%s\n" "$TF_FILES_CHANGED"

declare MODULES_DIR
if [[ $TF_FILES_CHANGED != "" ]]
then
    MODULES_DIR=$(echo "$TF_FILES_CHANGED" | xargs -L1 dirname | uniq)
    printf "INFO: MODULES_DIR value is \n%s\n" "$MODULES_DIR"
fi

## logic

for DIR in $MODULES_DIR
do
    printf "INFO: Reset to project home directory.\n"
    cd "${PROJECT_ROOT}" || exit
    printf "INFO: Changing into %s dir if it still exists.\n" "${DIR}"
    cd "$DIR" || continue

    if [[ ! -f ".terraform/modules/modules.json"  ]]
    then
        printf "INFO: Detected this module has not be initilized, skipping.\n"
        return
    fi

    printf "INFO: Checking for Terraform resources.\n"
    TF_RSRC_COUNT=$(find ./ -maxdepth 1 -type f \( -iname \*.tf -o -iname \*.hcl \) | wc -l)
    printf "INFO: Found %s valid resources.\n" "$TF_RSRC_COUNT"

    if [[ $TF_RSRC_COUNT == 0 ]]
    then
        printf "INFO: No Terraform or Terragrunt resources found, skipping.\n"
        continue
    fi

    # Do not allow in-project shared modules
    doNotAllowSharedModulesInsideDeploymentProjects

    # best practices and security scanning
    terraformCompliance

    # linting and syntax formatting
    terraformLinting

    # generate docs and meta-data only if checks do not fail
    documentation

    # supply chain attastation
    generateSBOM
done

## wrap up

cd "$ORIG_PWD" || exit

printf "INFO: Git pre-commit hook completed.\n"
