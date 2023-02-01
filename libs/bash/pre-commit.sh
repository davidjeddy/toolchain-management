#!/bin/bash -e

## functions

function doNotUseLocalModulesOutsideProject() {
    printf "INFO: Do not use local modules.\n"

    if [[ ! -f ".terraform/modules/modules.json"  ]]
    then
        printf "INFO: Detected this module has not be initilized. Doing that for you now.\n"
        terraform init
    fi

    #shellcheck disable=SC2002 # We do want to cat the file contents and pipeline into jq
    MODULES_IN_USE=$(cat ".terraform/modules/modules.json" | jq '.Modules[] | .Source')

    for MODULE in $MODULES_IN_USE
    do
        echo "INFO: Evaluating $MODULE as a module location."

        # empty location, root of module
        if [[ -n "$MODULE" ]]; then
            continue
        fi
        
        # local sub-module provided by a hosted shared module
        if [[ "$MODULE" == "./modules"* ]]; then
            continue
        fi

        # Worldline hosted shared modules. Ideal.
        if [[ "$MODULE" == *"gitlab.test.igdcs.com"* ]]; then
            continue
        fi

        # Hashicorp public registery. Ok, but not ideal.
        if [[ "$MODULE" == *"registry.terraform.io"* ]]; then
            continue
        fi

        echo "ERROR: Un-recognized or un-allowed Terraform module location: $MODULE. Exiting."
        exit 1
    done
}

function documentation() {
    printf "INFO: documentation.\n"
    if [[ ! -f "./README.md" ]]
    then
        printf "ALERT: README.md not found inh module, creating from template.\n"
        echo "# $(pwd)
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->" > ./README.md
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


function terraformTools() {
    printf "INFO: Executing Terraform tooling.\n"
    # execute tooling on dir

    # code formatting, complaince, documentation, linting, and security checking tools that can be run locally.

    # code linting / styling
    printf "INFO: Terraform/Terragrunt fmt and linting...\n"
    terraform fmt -recursive .
    terragrunt hclfmt .
    tflint --color .

    printf "INFO: checkov...\n"
    checkov --directory . --framework terraform --skip-path ./libs --quiet

    # Temp disabled due to two bugs with terrascan
    # https://github.com/tenable/terrascan/issues/1262 and https://github.com/tenable/terrascan/issues/1266
    # printf "INFO: terrascan...\n"
    # terrascan scan --iac-type terraform --non-recursive

    printf "INFO: tfsec...\n"
    tfsec . --concise-output --exclude-downloaded-modules
}

# vars
GIT_ROOT="$(pwd)"
MODULES_DIR=$(git diff --name-only --cached | xargs -L1 dirname | uniq)

## config output

printf "INFO: GIT_ROOT is %s\n" "$GIT_ROOT"
printf "INFO: All directories with changes:\n%s\n" "$MODULES_DIR"

## logic

for DIR in $MODULES_DIR
do
    # Reset to project root to be safe
    printf "INFO: Reset to project home directory.\n"
    cd "$GIT_ROOT" || exit

    printf "INFO: Changing into %s dir if it still exists.\n" "${DIR}"
    cd "$DIR" || continue

    printf "INFO: Checking for Terraform resources.\n"
    TF_RSRC_COUNT=$(find ./ -maxdepth 1 -type f \( -iname \*.tf -o -iname \*.hcl \) | wc -l)
    printf "INFO: Found %s valid resources.\n" "$TF_RSRC_COUNT"
    if [[ $TF_RSRC_COUNT == 0 ]]
    then
        printf "INFO: No Terraform or Terragrunt resources found, skipping.\n"
        continue
    fi

    if [[ $TF_MODULE_DEV != "true" ]]
    then
        doNotUseLocalModulesOutsideProject
    else
        printf "WARN: In Terraform module development mode, skipping doNotUseLocalModulesOutsideProject().\n"
    fi
    terraformTools

    # generate docs and meta-data only if checks do not fail
    documentation
    generateSBOM
done

## wrap up

cd "$GIT_ROOT" || exit

printf "INFO: Git pre-commit hook completed.\n"
