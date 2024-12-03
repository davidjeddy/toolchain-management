#!/bin/false

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

# DO NOT USE THIS unless you are 110% sure you want to hard reset your localhost.
# This DELETES many programs.
# This DELETES .bashrc
# This DELETES .toolchainrc

# example sudo ./libs/bash/reset.sh
# usage sudo ./libs/bash/reset.sh

# version 0.2.0 - Remove tools installed via Aqua (deprecated) package manager - David Eddy
# version 0.1.0 - FIX to only support Fedora hosts and reset .bashrc from source - David Eddy
# version 0.0.1 - David Eddy

# logic

printf "INFO: Starting...\n"

printf "INFO: Resetting .bashrc from init provided by (Fedora) host OS.\n"
rm "$HOME/.bashrc"
cp /etc/skel/.bashrc "$HOME/.bashrc"

if [[ $(which aqua) ]]
then
    printf "WARN: Removing packages managed Aqua (one time action).\n"
    aqua remove --all
    printf "WARN: Removing Aqua packages manager (one time action)."
    rm -rf "$HOME/.local/share/aquaproj-aqua"
fi

# Just plain `pip` here, nothing to see
if [[ $(which pip) ]]
then
    printf "WARN: Removing packages managed PIP (one time action).\n"
    pip uninstall \
      --yes \
      --requirement requirements.txt
fi

# Incase the OS knows it as `pip3`
if [[ $(which pip3) ]]
then
    printf "WARN: Removing packages managed PIP (one time action).\n"
    pip3 uninstall \
      --yes \
      --requirement requirements.txt
fi

# 0.61.0
yes | sudo rm -f "$HOME/.tool-versions " || true
yes | sudo rm -f "$HOME/.toolchainrc" || true
yes | sudo rm -rf "$HOME/.asdf/" || true
yes | sudo rm -rf "$HOME/.local/lib/python3.12/site-packages" || true
yes | sudo rm /usr/bin/docker || true

# 0.59.0
yes | sudo rm -rf "$HOME/.local/bin/" || true
yes | sudo rm -rf "$HOME/.local/bin/mavenn" || true
yes | sudo rm -rf "$HOME/.local/bin/sonar-scanner" || true
yes | sudo rm -rf "$HOME/.kics-installer" || true
yes | sudo rm -rf "$HOME/.aqua" || true
yes | sudo rm -rf "$HOME/.go" || true
yes | sudo rm -rf "$HOME/.goenv" || true
yes | sudo rm -rf "$HOME/.local/lib/python3*" || true
yes | sudo rm -rf "$HOME/.m2" || true
yes | sudo rm -rf "$HOME/.pyenv" || true
yes | sudo rm -rf "$HOME/.terraform.d/plugin-cache" || true

# 0.56.0
yes | sudo rm -rf /usr/bin/maven || true
yes | sudo rm -rf /usr/bin/mvn || true
yes | sudo rm -rf /usr/bin/pip* || true
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
