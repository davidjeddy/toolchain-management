#!/bin/bash -l

# set -exo pipefail # when debuggin
set -eo pipefail

# declare vars
declare AQUA_VER
declare GO_VER
declare GOENV_VER
declare LOCALSTACK_VER
declare MAVEN_VER
declare ONELOGIN_AWS_CLI_VER
declare PYENV_VER
declare PYTHON_VER
declare TF_VER
declare TG_VER
declare TOFU_VER

# set var values

## https://github.com/aquaproj/aqua
export AQUA_VER="2.30.0"
## https://github.com/golang/go
export GO_VER="1.21"
## https://github.com/syndbg/goenv
export GOENV_VER="2.2.1"
## https://github.com/localstack/localstack
export LOCALSTACK_VER="3.5.0"
## https://maven.apache.org/
export MAVEN_VER="3.9.8"
## https://pypi.org/project/onelogin-aws-cli/
export ONELOGIN_AWS_CLI_VER="0.1.19"
## https://www.python.org/downloads/
export PYTHON_VER="3.8.18"
## https://github.com/pyenv/pyenv
export PYENV_VER="2.4.8"
## https://github.com/hashicorp/terraform
export TF_VER="1.6.2"
## https://github.com/gruntwork-io/terragrunt
export TG_VER="0.64.1"
## https://github.com/opentofu
export TOFU_VER="1.8.0"

# System Tools
echo "AQUA_VER: $AQUA_VER"
echo "GO_VER: $GO_VER"
echo "GOENV_VER: $GOENV_VER"
echo "LOCALSTACK_VER: $LOCALSTACK_VER"
echo "MAVEN_VER: $MAVEN_VER"
echo "ONELOGIN_AWS_CLI_VER: $ONELOGIN_AWS_CLI_VER"
echo "PYENV_VER: $PYENV_VER"
echo "PYTHON_VER: $PYTHON_VER"
echo "TF_VER: $TF_VER"
echo "TG_VER: $TG_VER"
echo "TOFU_VER: $TOFU_VER"

# .*-version managed language runtimes
echo "$GO_VER" > .go-version
echo "$PYTHON_VER" > .python-version
echo "$TF_VER" > .terraform-version
echo "$TG_VER" > .terragrunt-version
echo "$TOFU_VER" > .tofu-version

# read version
echo "GO_VER: $(cat .go-version)"
echo "PYTHON_VER: $(cat .python-version)"
echo "TF_VER: $(cat .terraform-version)"
echo "TG_VER: $(cat .terragrunt-version)"
echo "TOFU_VER: $(cat .tofu-version)"
