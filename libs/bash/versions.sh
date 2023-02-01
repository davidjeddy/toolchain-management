#!/bin/bash -e

# declare vars

# AWS tools
declare AWSCLI_VER
declare IPJTT_VER

# Terraform tools
declare TFENV_VER
declare TF_VER
declare TGENV_VER
declare TG_VER

declare INFRACOST_VER
declare TFDOCS_VER
declare TFLINT_VER
declare TFSEC_VER
declare TRSCAN

# Misc tools
declare PKR_VER

# System Tools
declare PYTHON_VER

# set var values

# https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html
export AWSCLI_VER="2.0.30"
# https://github.com/flosell/iam-policy-json-to-terraform/releases
export IPJTT_VER="1.8.1"

# Terraform related tools
export TFENV_VER="3.0.0"
export TF_VER="1.3.0"
export TGENV_VER="0.0.3"
export TG_VER="0.42.5"

export INFRACOST_VER="0.10.15"
export TFDOCS_VER="0.16.0"
export TFLINT_VER="0.43.0"
export TFSEC_VER="1.22.0"
export TRSCAN="1.17.1"

# Misc tools
export PKR_VER="1.8.1"

# System Tools

export PYTHON_VER="3.8.12"
