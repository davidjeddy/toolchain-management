#!/usr/bin/env bash

set -e

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
declare TRIVY_VER

# Misc tools
declare PKR_VER

# System Tools
declare PYTHON_VER  
declare PYENV_VER
declare XEOL_VER

# set var values

# AWS related tools
## https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html
export AWSCLI_VER="2.13.8"
## https://github.com/flosell/iam-policy-json-to-terraform/releases
export IPJTT_VER="1.8.2"
## https://pypi.org/project/onelogin-aws-cli/
export ONELOGIN_AWS_CLI_VER="0.1.19"

# Iac related tools
## https://github.com/bridgecrewio/checkov/releases
export CHECKOV_VER="3.1.31"
## https://github.com/infracost/infracost/releases
export INFRACOST_VER="0.10.34"
## https://github.com/Checkmarx/kics/releases
export KICS_VER="1.7.5"
## https://github.com/hashicorp/terraform/releases - managed by tfenv, this is just a default
export TF_VER="1.6.2"
## https://github.com/terraform-docs/terraform-docs/releases
export TFDOCS_VER="0.17.0"
## https://github.com/tfutils/tfenv/releases
export TFENV_VER="3.0.0"
## https://github.com/aquasecurity/tfsec/releases
export TFSEC_VER="1.28.5"
## https://github.com/terraform-linters/tflint/releases
export TFLINT_VER="0.47.0"
## https://github.com/aquasecurity/trivy/releases
export TRIVY_VER="0.49.1"
## https://github.com/gruntwork-io/terragrunt/releases
export TG_VER="0.48.7"
## https://github.com/tgenv/tgenv/releases
export TGENV_VER="1.1.0"
## https://github.com/tofuutils/tofuenv/tags
export TOFUENV_VER="1.0.3"
## https://github.com/tofu/tofu/releases
export TOFU_VER="1.6.0"

# Misc tools
## https://github.com/hashicorp/packer/releases
export PKR_VER="1.10.2"

# System Tools

## https://github.com/syndbg/goenv/releases
export GOENV_VER="2.1.4"
## https://github.com/golang/go/tags
### KICS only supports up to GO 1.18.2 as of 2023-03-10
export GO_VER="1.18.2"
## https://www.python.org/downloads/
# DO NOT CHANGE THIS until after the jenkins worker is updated paste RHEL 7.9
export PYTHON_VER="3.8.18"
# DEPRECATED. USE PYENV_VER
export PYTHON_MINOR_VER="3.8"
# DEPRECATED. USE PYENV_VER
export PYTHON_MAJOR_VER="3"

## https://github.com/pyenv/pyenv/tags
export PYENV_VER="2.3.36"
## https://github.com/xeol-io/xeol/tags
export XEOL_VER="0.6.0"

# output versions to end-user visibility
printf "INFO: Output tool target versions.\n"

# System Tools
echo "GOENV_VER: $GOENV_VER"
echo "GO_VER: $GO_VER"
echo "PYTHON_VER: $PYTHON_VER"
echo "PYENV_VER: $PYENV_VER"
echo "PYTHON_MINOR_VER: $PYTHON_MINOR_VER"

echo "XEOL_VER: $XEOL_VER"

# AWS tools
echo "AWSCLI_VER: $AWSCLI_VER"
echo "IPJTT_VER: $IPJTT_VER"
echo "ONELOGIN_AWS_CLI_VER: $ONELOGIN_AWS_CLI_VER"

# Misc tools
echo "PKR_VER: $PKR_VER"

# IaC version controllers
echo "TOFU_VER: $TOFU_VER"
echo "TF_VER: $TF_VER"
echo "TFENV_VER: $TFENV_VER"
echo "TG_VER: $TG_VER"
echo "TGENV_VER: $TGENV_VER"
echo "TOFUENV_VER: $TOFUENV_VER"

# IaC Compliance
echo "INFRACOST_VER: $INFRACOST_VER"
echo "KICS_VER: $KICS_VER"
echo "TFDOCS_VER: $TFDOCS_VER"
echo "TFLINT_VER: $TFLINT_VER"
echo "TFSEC_VER: $TFSEC_VER"
echo "TRIVY_VER: $TRIVY_VER"
