#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1090
# source "$SESSION_SHELL" || exit 1 # do not need nor want to do this here. Kept for alignment

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

if [[ $(cat /etc/*release) != *"Fedora"* ]]
then
    printf "ERR: Script not supported on non-Fedora hosts.\n"
    exit 1
fi

# documentation

# example sudo ./libs/bash/reset.sh
# usage sudo ./libs/bash/reset.sh

# version 0.1.0 - FIX to only support Fedora hosts and reset .bashrc from source - David Eddy
# version 0.0.1 - David Eddy

# execution

printf "INFO: Starting...\n"

printf "INFO: Resetting .bashrc from init provided by (Fedora) host.\n"
rm "$HOME/.bashrc"
cp /etc/skel/.bashrc "$HOME/.bashrc"

printf "INFO: Remove OS package manager packages\n"
sudo dnf remove -y  session-manager-plugin

if [[ $(which aqua) ]]
then
    printf "INFO: Remove Aqua managed packages\n"
    aqua remove --all
fi

printf "INFO: Remove shell configuration, language *env helpers, IAC plugin cache, and package managers from \$HOME\n"

yes | sudo rm -rf "$HOME/.kics-installer" || true
yes | sudo rm -rf "$HOME/.aqua" || true
yes | sudo rm -rf "$HOME/.go" || true
yes | sudo rm -rf "$HOME/.goenv" || true
yes | sudo rm -rf "$HOME/.local/lib/python3*" || true
yes | sudo rm -rf "$HOME/.m2" || true
yes | sudo rm -rf "$HOME/.pyenv" || true
yes | sudo rm -rf "$HOME/.terraform.d/plugin-cache" || true

printf "INFO: Removing all Toolchain managed tool binaries\n"

# For 0.59.0
yes | sudo rm -rf "$HOME/.local/bin/mavenn" || true
yes | sudo rm -rf "$HOME/.local/bin/session-manager-plugin" || true
yes | sudo rm -rf "$HOME/.local/bin/sonar-scanner" || true

# For 0.56.0
yes | sudo rm -rf /usr/bin/maven || true
yes | sudo rm -rf /usr/bin/mvn || true
yes | sudo rm -rf /usr/bin/pip3* || true
yes | sudo rm -rf /usr/bin/pydoc3* || true
yes | sudo rm -rf /usr/bin/sonar-scanner || true
yes | sudo rm /usr/bin/iam-policy-json-to-terraform || true
yes | sudo rm /usr/bin/infracost || true
yes | sudo rm /usr/bin/kics || true
yes | sudo rm /usr/bin/packer || true
yes | sudo rm /usr/bin/pydoc || true
yes | sudo rm /usr/bin/session-manager-plugin  || true
yes | sudo rm /usr/bin/terraform || true
yes | sudo rm /usr/bin/terraform-docs || true
yes | sudo rm /usr/bin/terragrunt  || true
yes | sudo rm /usr/bin/terrascan || true
yes | sudo rm /usr/bin/tfenv || true
yes | sudo rm /usr/bin/tflint || true
yes | sudo rm /usr/bin/tfsec || true
yes | sudo rm /usr/bin/tgenv || true
yes | sudo rm /usr/bin/tofu || true
yes | sudo rm /usr/bin/tofuenv || true
yes | sudo rm /usr/bin/xeol || true

printf "INFO: Done. Open a new session to take effect\n"
