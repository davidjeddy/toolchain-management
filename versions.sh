#!/bin/bash -l

# set -exo pipefail # for debugging
set -eo pipefail

# declare vars
declare AQUA_VER
declare GO_VER
declare GOENV_VER
declare MAVEN_VER
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
## https://maven.apache.org/
export MAVEN_VER="3.9.8"
## https://www.python.org/downloads/
export PYTHON_VER="3.12.5"
## https://github.com/pyenv/pyenv
export PYENV_VER="2.4.8"
## https://docs.sonarsource.com/sonarqube/latest/
export SONARQUBE_SCANNER_VER="4.2.0.1873"
## https://github.com/hashicorp/terraform
export TF_VER="1.6.2"
## https://github.com/gruntwork-io/terragrunt
export TG_VER="0.64.1"
## https://github.com/opentofu
export TOFU_VER="1.8.0"

# .*-version managed language runtimes
echo "$GO_VER" > .go-version
echo "$PYTHON_VER" > .python-version
echo "$TF_VER" > .terraform-version
echo "$TG_VER" > .terragrunt-version
echo "$TOFU_VER" > .tofu-version

# System Tools
echo "AQUA_VER: $AQUA_VER"
echo "GO_VER: $GO_VER"
echo "GOENV_VER: $GOENV_VER"
echo "MAVEN_VER: $MAVEN_VER"
echo "PYENV_VER: $PYENV_VER"
echo "PYTHON_VER: $PYTHON_VER"
echo "SONARQUBE_SCANNER_VER: $SONARQUBE_SCANNER_VER"
echo "TF_VER: $TF_VER"
echo "TG_VER: $TG_VER"
echo "TOFU_VER: $TOFU_VER"
