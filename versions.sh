#!/usr/bin/env bash

set -e

# declare vars
declare AQUA_VER
declare GOENV_VER
declare KICS_VER
declare ONELOGIN_AWS_CLI_VER
declare PYENV_VER

# set var values

## https://github.com/aquaproj/aqua/tags
export AQUA_VER="2.27.1"
## https://github.com/syndbg/goenv/releases
export GOENV_VER="2.1.14"
## TODO Move this to Aqua once supported
## https://github.com/Checkmarx/kics/releases
export KICS_VER="1.7.5"
## https://pypi.org/project/onelogin-aws-cli/
export ONELOGIN_AWS_CLI_VER="0.1.19"
## https://github.com/pyenv/pyenv/tags
export PYENV_VER="2.3.36"

# System Tools
echo "AQUA_VER: $AQUA_VER"
echo "GOENV_VER: $GOENV_VER"
echo "KICS_VER: $KICS_VER"
echo "ONELOGIN_AWS_CLI_VER: $ONELOGIN_AWS_CLI_VER"
echo "PYENV_VER: $PYENV_VER"

# .*-version managed language runtimes
echo "GO_VER: $(cat .go-version)"
echo "PYTHON_VER: $(cat .python-version)"
