#!/bin/bash

## configuration

set -eo pipefail

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## preflight

## functions

## logic

if [[ $(cat /etc/fedora-release ) != "Fedora release 40 (Forty)" ]]
then
    printf "ERR: You are not running a native Fedora 40 installation. This process if not for you.\n"
fi

printf "INFO: Starting upgrade process, this will require a reboot.\n"

sudo dnf upgrade --refresh
sudo dnf install dnf-plugin-system-upgrade
sudo dnf system-upgrade download --releasever=42
sudo dnf clean packages

printf "INFO: Done. Rebooting.\n"

sudo dnf system-upgrade reboot

