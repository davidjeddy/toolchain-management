#!/bin/bash -e

# Required
# ENV VAR (pwd) must be set

# TODO use `parallel` to execute functions at the same time to reduce wait time

# Make tmp dir to hold artifacts and reports per module
function createTmpDir() {
    if [[ ! -d "./.tmp" ]]
    then
        mkdir -p "./.tmp"
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
    MODULE_SOURCES=$(cat ".terraform/modules/modules.json" | jq '.Modules[] | .Source')

    for MODULE_SOURCE in $MODULE_SOURCES
    do
        echo "INFO: Checking module source $MODULE_SOURCE"

        # https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
        if [[ "$MODULE_SOURCE" =~ "file://"* ]]
         then
            echo "ERROR: It is not allowed to use shared modules placed inside a deployment project. Please use published modules from a registry."
            exit 1
        fi
    done
}

function documentation() {
    printf "INFO: Validating generated documentation.\n"

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

    # Fail pipeline if README is not up to date
    if [[ $(whoami) == 'jenkins' && $(git status -s) != "" ]]
    then
        printf "ERR: README.md needs to be updated as part of the pre-commit befvore pushing."
        exit 1
    fi
    printf "INFO: README.md validated, changes added to Git stage.\n"
    git add README.md
}

function generateSBOM() {
    printf "INFO: generating sbom using checkov (Ignore warning about 'Failed to download module', this is due to a limitation of checkov)...\n"

    # Do not generate SBOM is jenkins user, just ensure it exists
    if [[ $(whoami) == 'jenkins' && ! -f sbom.xml ]]
    then
        printf "ERR: sbom.xml missing, failing."
        exit 1
    elif [[ $(whoami) == 'jenkins' && -f sbom.xml ]]
    then
        printf "INFO: Automation user detected, not generated sbom.xml"
        return 0
    fi

    {
        if [[ -f "checkov.yml" ]]
        then
            # use configuration file if present. Created due to terraform/deployments/terraform/aws/worldline-gc-keycloak-dev/eu-west-1/keycloak/iohd being created BEFORE complaince was mandatory    
            checkov \
                --config-file checkov.yml \
                --directory . \
                --output cyclonedx \
                > "$(pwd)/sbom.xml"
        else
            checkov \
                --directory . \
                --output cyclonedx \
                > "$(pwd)/sbom.xml"
        fi
        git add sbom.xml || true
    } || {
        cat "$(pwd)/sbom.xml" || exit 1
        echo "ERR: checkov SBOM failed to generate.":q
        exit 1
    }
}

function terraformCompliance() {
    printf "INFO: Executing Compliance and SAST scanners...\n"

    printf "INFO: checkov (Ignore warning about 'Failed to download module', this is due to a limitation of checkov)...\n"
    {
        rm -rf "$(pwd)/.tmp/junit-checkov.xml" || exit 1
        touch "$(pwd)/.tmp/junit-checkov.xml" || exit 1
        if [[ -f "checkov.yml" ]]
        then
            printf "INFO: checkov configuration file found, using it.\n"
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
            printf "INFO: checkov configuration NOT file found.\n"
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
        cat "$(pwd)/.tmp/junit-checkov.xml" || exit 1
        echo "ERR: checkov failed. Check report saved to .tmp/junit-checkov.xml"
        exit 1
    }

    printf "INFO: KICS executing...\n"
    {
        rm -rf "$(pwd)/.tmp/junit-kics.xml" || exit 1
        touch "$(pwd)/.tmp/junit-kics.xml" || exit 1
        if [[ -f "kics.yml" ]]
        then
            printf "INFO: KICS configuration file found, using it.\n"
            # kics cli argument `--queries-path` must contain an absolute path, else a `/` gets pre-pended.
            kics scan \
                --cloud-provider "aws" \
                --config "kics.yml" \
                --exclude-paths "*" \
                --no-color \
                --no-progress \
                --output-name "junit-kics" \
                --output-path "./.tmp" \
                --path "./" \
                --queries-path "$(pwd)/.tmp/toolchain-management/libs/kics/assets/queries/terraform/aws" \
                --report-formats "junit" \
                --type "Terraform"
        else
            printf "INFO: KICS configuration NOT file found.\n"
            kics scan \
                --cloud-provider "aws" \
                --exclude-paths "*" \
                --no-color \
                --no-progress \
                --output-name "junit-kics" \
                --output-path "./.tmp" \
                --path "./" \
                --queries-path "$(pwd)/.tmp/toolchain-management/libs/kics/assets/queries/terraform/aws" \
                --report-formats "junit" \
                --type "Terraform"
        fi
    } || {
        cat "$(pwd)/.tmp/junit-kics.xml" || exit 1
        echo "ERR: kics failed. Check report saved to .tmp/junit-kics.xml"
        exit 1
    }

    printf "INFO: tfsec executing...\n"
    {
        rm -rf "$(pwd)/.tmp/junit-tfsec.xml" || exit 1
        touch "$(pwd)/.tmp/junit-tfsec.xml" || exit 1
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
                > "$(pwd)/.tmp/junit-tfsec.xml"
        else
            printf "INFO: tfsec configuration NOT file found.\n"
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
        cat "$(pwd)/.tmp/junit-tfsec.xml" || exit 1
        echo "ERR: tfsec failed. Check report saved to .tmp/junit-tfsec.xml"
        exit 1
    }

    # trivy only scans deployment modules
    if [[ -f "$(pwd)/.terraform.lock.hcl" ]]
    then
        printf "INFO: trivy executing...\n"
        {
            rm -rf "$(pwd)/.tmp/junit-trivy.xml" || exit 1
            touch "$(pwd)/.tmp/junit-trivy.xml" || exit 1
            if [[ -f "trivy.yml" ]]
            then
                # use configuration file if present.
                printf "INFO: trivy configuration file found, using it.\n"
                trivy scan \
                    --config trivy.yml \
                    --iac-type terraform \
                    --log-level error \
                    --non-recursive \
                    --output junit-xml \
                    --use-colors f \
                    > .tmp/junit-trivy.xml
            else
                printf "INFO: trivy configuration NOT file found.\n"
                trivy scan \
                    --iac-type terraform \
                    --log-level error \
                    --non-recursive \
                    --output junit-xml \
                    --use-colors f \
                    > .tmp/junit-trivy.xml
            fi
        } || {
            cat "$(pwd)/.tmp/junit-trivy.xml" || exit 1
            echo "ERR: trivy failed. Check Junit reports in .tmp"
            exit 1
        }
    fi

    # EOL scanning tool
    # printf "INFO: xeol executing...\n"
    # {
    #     rm -rf "$(pwd)/.tmp/junit-xeol.xml" || exit 1
    #     touch "$(pwd)/.tmp/junit-xeol.xml" || exit 1
    #     if [[ -f "trivy.yml" ]]
    #     then
    #         # use configuration file if present.
    #         printf "INFO: xeol configuration file found, using it.\n"
    #         xeol \
    #             --config xeol.yml \
    #             --fail-on-eol-found \
    #             --file "$(pwd)/.tmp/junit-xeol.xml"\
    #             --lookahead 1y \
    #             --name "$(basename "$(pwd)")" \
    #             --project-name "$(basename "$(pwd)")"
    #     else
    #         printf "INFO: xeol configuration NOT file found.\n"
    #         xeol \
    #             --fail-on-eol-found \
    #             --file "$(pwd)/.tmp/junit-xeol.xml"\
    #             --lookahead 1y \
    #             --name "$(basename "$(pwd)")" \
    #             --project-name "$(basename "$(pwd)")"

    #     fi
    # } || {
    #     cat "$(pwd)/.tmp/junit-xeol.xml" || exit 1
    #     echo "ERR: xeol failed. Check Junit reports in .tmp"
    #     exit 1
    # }
}

function terraformLinting() {
    printf "INFO: Executing Terraform Linting.\n"

    printf "INFO: Terraform/Terragrunt fmt and linting...\n"
    terraform fmt -no-color -recursive . 
    terragrunt hclfmt .
    tflint --chdir="$(pwd)" --fix --module --no-color
}
