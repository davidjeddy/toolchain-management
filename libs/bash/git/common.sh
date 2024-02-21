#!/bin/bash -e

## fn()

function exec() {
  # args

  local PRJ_ROOT
  if [[ ! $1 ]]
  then 
      printf "ERR: Argument 1 must be path to root of project.\n"
      exit 1
  fi
  PRJ_ROOT="${1}"

  local CHANGE_LIST
  if [[ ! $2 ]]
  then 
      printf "ERR: Argument 2 must be change file list.\n"
      exit 1
  fi
  CHANGE_LIST="${2}"

  # get a list of changed files when using only the git staged list against previouse commit
  local TF_FILES_CHANGED
  # shellcheck disable=SC2002
  TF_FILES_CHANGED=$(printf "%s" "${CHANGE_LIST}" | \
      grep tf\$ | \
      grep -v .tmp/ | \
      grep -v docs/ | \
      grep -v examples/ | \
      grep -v libs/ | \
      grep -v README.md | \
      grep -v sbom.xml | \
      grep -v terraform.tf \
      || true \
  )
  export TF_FILES_CHANGED
  printf "INFO: TF_FILES_CHANGED value is \n%s\n" "$TF_FILES_CHANGED"

  if  [[ $TF_FILES_CHANGED == "" ]]
  then
      printf "INFO: TF_FILES_CHANGED is empty; no iac changes detected, exiting.\n"
      exit 0
  fi

  local MODULES_DIR
  if [[ $TF_FILES_CHANGED != "" ]]
  then
      MODULES_DIR=$(echo "$TF_FILES_CHANGED" | xargs -L1 dirname | sort | uniq)
      printf "INFO: MODULES_DIR value is \n%s\n" "$MODULES_DIR"
  fi

  for DIR in $MODULES_DIR
  do
    printf "INFO: Changing into %s dir if it still exists.\n" "${PRJ_ROOT}/${DIR}"
    cd "$PRJ_ROOT/$DIR" || exit 1

    # If a lock file exists, AND the cache directory does not, the module needs to be initilized.
    if [[ -f "$(pwd)/terraform.lock.hcl" && ! -d "$(pwd)/terraform" ]]
    then
        terraform init -no-color
        terraform providers lock -platform=linux_amd64
    fi

    # Create tmp dir to hold artifacts and reports
    createTmpDir

    # Do not allow in-project shared modules
    doNotAllowSharedModulesInsideDeploymentProjects

    # linting and syntax formatting
    iacLinting

    # Generate sbom.xml only if the invoking scripts is pre-commit. No other time should generate sbom
    if [[ "${0?}" == *pre-commit ]]
    then
        # generate docs and meta-data
        documentation

        # generate sbom for supply chain suditing
        generateSBOM
    fi

    # Finally, if the invoking script name is pre-push, also run the full compliance tooling
    if [[ "${0?}" == *pre-push ]]
    then
        iacCompliance
    fi
  done
}

# Make tmp dir to hold artifacts and reports per module
function createTmpDir() {
    if [[ ! -d "$(pwd)/.tmp" ]]
    then
        mkdir -p "$(pwd)/.tmp"
    fi
}

function doNotAllowSharedModulesInsideDeploymentProjects() {
    printf "INFO: Do not allow shared modules inside a deployment project.\n"

    #shellcheck disable=SC2002 # We do want to cat the file contents and pipeline into jq
    if [[ ! -f "$(pwd)/terraform/modules/modules.json" ]]
    then
        return 0
    fi

    # shellcheck disable=SC2002
    MODULE_SOURCES=$(cat "$(pwd)/terraform/modules/modules.json" | jq '.Modules[] | .Source')

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

    if [[ ! -f "$(pwd)/README.md" ]]
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
    # if [[ $(whoami) == 'jenkins' && $(git status -s) != "" ]]
    # then
    #     printf "ERR: README.md needs to be updated as part of the pre-commit before pushing.\n"
    #     git diff README.md
    #     exit 1
    # fi

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
            # use configuration file if present. Created due to terraform/aws/worldline-gc-keycloak-dev/eu-west-1/keycloak/iohd being created BEFORE complaince was mandatory    
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
        echo "ERR: checkov SBOM failed to generate."
        cat "sbom.xml"
        exit 1
    }
}

function iacCompliance() {
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
                --file "*.tf" \
                --file "*.hcl" \
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
                --file "*.tf" \
                --file "*.hcl" \
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
        echo "ERR: checkov failed. Check report saved to .tmp/junit-checkov.xml"
        cat "$(pwd)/.tmp/junit-checkov.xml"
        exit 1
    }

    # Note: `PRJ_ROOT` is defined in pre_commit.sh and must point to the root of the project.
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
                --output-path "$(pwd)/.tmp" \
                --path "$(pwd)/" \
                --queries-path "${PRJ_ROOT}/.tmp/toolchain-management/.tmp/kics/assets/queries/terraform/aws" \
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
                --output-path "$(pwd)/.tmp" \
                --path "$(pwd)/" \
                --queries-path "${PRJ_ROOT}/.tmp/toolchain-management/.tmp/kics/assets/queries/terraform/aws" \
                --report-formats "junit" \
                --type "Terraform"
        fi
    } || {
        echo "ERR: kics failed. Check report saved to .tmp/junit-kics.xml"
        cat "$(pwd)/.tmp/junit-kics.xml"
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
        echo "ERR: tfsec failed. Check report saved to .tmp/junit-tfsec.xml"
        cat "$(pwd)/.tmp/junit-tfsec.xml"
        exit 1
    }

    # trivy only scans deployment modules
    # FATAL	sbom scan error: scan error: scan failed: failed analysis: SBOM decode error: cyclonedx-xml scanning is not yet supported
    # if [[ -f "$(pwd)/.terraform.lock.hcl" ]]
    # then
    #     printf "INFO: trivy executing...\n"
    #     {
    #         rm -rf "$(pwd)/.tmp/junit-trivy.xml" || exit 1
    #         touch "$(pwd)/.tmp/junit-trivy.xml" || exit 1
    #         if [[ -f "trivy.yml" ]]
    #         then
    #             # use configuration file if present.
    #             printf "INFO: trivy configuration file found, using it.\n"
    #             trivy scan \
    #                 --config trivy.yml \
    #                 --log-level error \
    #                 --non-recursive \
    #                 --output junit-xml \
    #                 --use-colors f \
    #                 > .tmp/junit-trivy.xml
    #         else
    #             printf "INFO: trivy configuration NOT file found.\n"
    #             trivy scan \
    #                 --log-level error \
    #                 --non-recursive \
    #                 --output junit-xml \
    #                 --use-colors f \
    #                 > .tmp/junit-trivy.xml
    #         fi
    #     } || {
    #         echo "ERR: trivy failed. Check Junit reports in .tmp"
    #         cat "$(pwd)/.tmp/junit-trivy.xml"
    #         exit 1
    #     }
    # fi

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
    #     echo "ERR: xeol failed. Check Junit reports in .tmp"
    #     cat "$(pwd)/.tmp/junit-xeol.xml"
    #     exit 1
    # }
}

function iacLinting() {
    printf "INFO: Executing iac Linting.\n"

    printf "INFO: Terraform/Terragrunt fmt and linting...\n"
    terraform fmt -no-color -recursive .
    terragrunt hclfmt .

    printf "INFO: tflint executing...\n"
    {
        if [[ -f "tflint.hcl" ]]
        then
            tflint \
                --chdir="$(pwd)" \
                --config="tflint.hcl" \
                --no-module \
                --no-color \
                --format=junit \
                --ignore-module=SOURCE \
                > .tmp/junit-tflint.xml
        else
            tflint \
                --chdir="$(pwd)" \
                --no-module \
                --no-color \
                --format=junit \
                --ignore-module=SOURCE \
                > .tmp/junit-tflint.xml
        fi
    } || {
        echo "ERR: tflint failed. Check Junit reports in .tmp"
        cat "$(pwd)/.tmp/junit-tflint.xml"
        exit 1
    }
}
