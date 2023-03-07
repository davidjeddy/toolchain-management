#!/bin/bash -e

# declare vars

# AWS tools
declare AWSCLI_VER
declare IPJTT_VER

# Terraform tools
declare CHECKOV_VER
declare KICS_VER
declare INFRACOST_VER
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

# set var values

# AWS related tools
## https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html
export AWSCLI_VER="2.0.30"
## https://github.com/flosell/iam-policy-json-to-terraform/releases
export IPJTT_VER="1.8.2"

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
export TFSEC_VER="1.28.1"
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

## https://go.dev/dl/
export PYTHON_VER="3.8.12"
export GOLANG_VER="1.20.1"
