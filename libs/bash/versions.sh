#!/bin/bash -e

# declare vars

# AWS tools
declare AWSCLI_VER
declare IPJTT_VER
declare ONELOGIN_AWS_CLI_VER

# Terraform tools
declare CHECKOV_VER
declare GOENV_VER
declare INFRACOST_VER
declare KICS_VER
declare TF_VER
declare TFDOCS_VER
declare TFENV_VER
declare TFLINT_VER
declare TFSEC_VER
declare TG_VER
declare TGENV_VER
declare TRSCAN_VER

# Misc tools
declare PKR_VER

# System Tools
declare PYTHON_VER
declare PYTHON_MINOR_VER
declare XEOL_VER

# set var values

# AWS related tools
## https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html
export AWSCLI_VER="2.9.13"
## https://github.com/flosell/iam-policy-json-to-terraform/releases
export IPJTT_VER="1.8.2"
## https://github.com/physera/onelogin-aws-cli
export ONELOGIN_AWS_CLI_VER="0.1.19"

# Terraform related tools
## https://github.com/bridgecrewio/checkov/releases
export CHECKOV_VER="2.3.28"
## https://github.com/infracost/infracost/releases
export INFRACOST_VER="0.10.17"
## https://github.com/Checkmarx/kics
export KICS_VER="1.6.10"
## https://github.com/hashicorp/terraform/releases - managed by tfenv
export TF_VER="1.3.9"
## https://github.com/terraform-docs/terraform-docs/releases
export TFDOCS_VER="0.16.0"
## https://github.com/tfutils/tfenv/releases
export TFENV_VER="3.0.0"
## https://github.com/terraform-linters/tflint/releases
export TFLINT_VER="0.45.0"
## https://github.com/aquasecurity/tfsec/releases
### Keep tfsec @ 1.28.0 until these issues are resilved
### https://github.com/aquasecurity/tfsec/issues/1935
### https://github.com/aquasecurity/tfsec/issues/1936
export TFSEC_VER="1.28.0"
## https://github.com/gruntwork-io/terragrunt/releases
export TG_VER="0.43.2"
## https://github.com/cunymatthieu/tgenv/releases
export TGENV_VER="0.0.3"
## https://github.com/tenable/terrascan/releases
export TRSCAN_VER="1.17.1"

# Misc tools
## https://github.com/hashicorp/packer/releases
export PKR_VER="1.8.6"

# System Tools

## https://github.com/syndbg/goenv
export GOENV_VER="2.0.6"
## https://github.com/golang/go/tags
### KICS only supports up to GO 1.18.2 as of 2023-03-10
export GO_VER="1.18.2"
## https://go.dev/dl/
export PYTHON_VER="3.8.12"
export PYTHON_MINOR_VER="3.8"
## https://github.com/xeol-io/xeol/tags
export XEOL_VER="0.3.3"

# output versions to end-user visibility
printf "INFO: Output tool target versions.\n"

# System Tools
echo "GOENV_VER: $GOENV_VER"
echo "GO_VER: $GO_VER"
echo "PYTHON_VER: $PYTHON_VER"
echo "PYTHON_MINOR_VER: $PYTHON_MINOR_VER"

echo "XEOL_VER: $XEOL_VER"

# AWS tools
echo "AWSCLI_VER: $AWSCLI_VER"
echo "IPJTT_VER: $IPJTT_VER"
echo "ONELOGIN_AWS_CLI_VER: $ONELOGIN_AWS_CLI_VER"

# Misc tools
echo "PKR_VER: $PKR_VER"

# Terraform/Terragrunt version controlers
echo "TFENV_VER: $TFENV_VER"
echo "TF_VER: $TF_VER"
echo "TGENV_VER: $TGENV_VER"
echo "TG_VER: $TG_VER"

# Terraform Compliance
echo "INFRACOST_VER: $INFRACOST_VER"
echo "KICS_VER: $KICS_VER"
echo "TFDOCS_VER: $TFDOCS_VER"
echo "TFLINT_VER: $TFLINT_VER"
echo "TFSEC_VER: $TFSEC_VER"
echo "TRSCAN_VER: $TRSCAN_VER"
