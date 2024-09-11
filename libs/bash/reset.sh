#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    printf "ERR: Script must be run with sudo or root permissions."
    exit 1
fi

# documentation

# example sudo ./libs/bash/reset.sh
# usage sudo ./libs/bash/reset.sh
# version 0.0.1 - David Eddy

# execution

printf "INFO: Starting...\n"

printf "INFO: Remove all lines between the start and end of \"# WL - GC - Centaurus - ...\" in your shell (bashrc*) profile configurations\n"
read -p "INFO: Press any key to continue"

vi /home/$SUDO_USER/.bashrc
vi /home/$SUDO_USER/.bash_profile

printf "INFO: Remove shell configuration, language *env helpers, IAC plugin cache, and package managers from \$HOME\n"

yes | rm -rf $HOME/.kics-installer || true
yes | rm -rf $HOME/.aqua || true
yes | rm -rf $HOME/.go || true
yes | rm -rf $HOME/.goenv || true
yes | rm -rf $HOME/.local/lib/python3* || true
yes | rm -rf $HOME/.m2 || true
yes | rm -rf $HOME/.pyenv || true
yes | rm -rf $HOME/.terraform.d/plugin-cache || true

printf "INFO: Removing all Toolchain managed tool binaries\n"

# For < 0.56.0
rm $HOME.worldline_pps_* || true
yes | rm -rf /usr/local/bin/localstack* || true
yes | rm -rf /usr/local/bin/maven || true
yes | rm -rf /usr/local/bin/mvn || true
yes | rm -rf /usr/local/bin/pip3* || true
yes | rm -rf /usr/local/bin/pydoc3* || true
yes | rm -rf /usr/local/bin/sonar-scanner || true
yes | rm -rf $HOME/.local/lib/python3* || true
yes | rm /usr/local/bin/iam-policy-json-to-terraform || true
yes | rm /usr/local/bin/infracost || true
yes | rm /usr/local/bin/kics || true
yes | rm /usr/local/bin/packer || true
yes | rm /usr/local/bin/session-manager-plugin  || true
yes | rm /usr/local/bin/terraform || true
yes | rm /usr/local/bin/terraform-docs || true
yes | rm /usr/local/bin/terragrunt  || true
yes | rm /usr/local/bin/terrascan || true
yes | rm /usr/local/bin/tfenv || true
yes | rm /usr/local/bin/tflint || true
yes | rm /usr/local/bin/tfsec || true
yes | rm /usr/local/bin/tgenv || true
yes | rm /usr/local/bin/tofu || true
yes | rm /usr/local/bin/tofuenv || true
yes | rm /usr/local/bin/xeol || true

# For >= 0.56.0
yes | rm -rf /usr/bin/maven || true
yes | rm -rf /usr/bin/mvn || true
yes | rm -rf /usr/bin/pip3* || true
yes | rm -rf /usr/bin/pydoc3* || true
yes | rm -rf /usr/bin/sonar-scanner || true
yes | rm /usr/bin/iam-policy-json-to-terraform || true
yes | rm /usr/bin/infracost || true
yes | rm /usr/bin/kics || true
yes | rm /usr/bin/packer || true
yes | rm /usr/bin/pydoc || true
yes | rm /usr/bin/session-manager-plugin  || true
yes | rm /usr/bin/terraform || true
yes | rm /usr/bin/terraform-docs || true
yes | rm /usr/bin/terragrunt  || true
yes | rm /usr/bin/terrascan || true
yes | rm /usr/bin/tfenv || true
yes | rm /usr/bin/tflint || true
yes | rm /usr/bin/tfsec || true
yes | rm /usr/bin/tgenv || true
yes | rm /usr/bin/tofu || true
yes | rm /usr/bin/tofuenv || true
yes | rm /usr/bin/xeol || true

printf "INFO: To verify we are in good shape, next we list the contains of /usr/local/bin and /usr/bin. No IAC, Golang, or Python binaries or directories should be listed\n"
read -p "INFO: Press any key to continue"

ls /usr/local/bin
ls /usr/bin

printf "INFO: Remove OS package manager packages\n"
sudo dnf remove session-manager-plugin

printf "INFO: Done. Open a new session to take effect\n"
