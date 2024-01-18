# Toolchain Management

## Table of Contents

- [Toolchain Management](#toolchain-management)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Purpose](#purpose)
  - [Requirements / Supported Platforms](#requirements--supported-platforms)
  - [Tools Includes (but are not limited to)](#tools-includes-but-are-not-limited-to)
    - [AWS](#aws)
    - [Terraform](#terraform)
    - [Language Run-times](#language-run-times)
  - [Usage](#usage)
    - [WARNING](#warning)
    - [Install](#install)
    - [Usage](#usage-1)
    - [Update Toolchain](#update-toolchain)
  - [Development](#development)
  - [Additional Information](#additional-information)

## Description

Collection of resources and tolls used to manage Terraform projects.

## Purpose

Ensure compliance in Terraform based projects via the shift-left pattern of presenting violations regarding organizational auditing, linting, security, and style guides as soon as an engineer attempts to save code. Additionally, toolchain has to ability to enforce the version of the tools installed. Ensure the engineering teams can stay up to date without messing around updating each to individually.

Currently only local machine and Jenkins pipeline tools are supported. 

Engineer saved code -> toolchain triggered (pre-commit hook) -> scanning tools execute -> if violations are found, the save is aborted


## Requirements / Supported Platforms

- [Linux](https://en.wikipedia.org/wiki/Linux) (kernal >= 4.x)
  - `sudo` ability
  - [Fedora](https://fedoraproject.org/)(recommended) or [RHEL](https://en.wikipedia.org/wiki/Red_Hat_Enterprise_Linux)(second option) based are the only distributions currently supported
    - [Worldline PPS Tribe Fedore VirtualBox VM Configuration](https://confluence.techno.ingenico.com/display/PPS/Installing+Fedora+Workstatio+38+Virtual+Machine+on+DWS+Workstation)
- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) >= 5.x
- [Git](https://git-scm.com/) >= 2.x

## Tools Includes (but are not limited to)

### AWS

- AWS CLI
- iam-policy-json-to-terraform

### Terraform

- Checkov
- Infracost
- KICS
- Terraform version manager
- Terragrunt version manager
- terrascan
- tf-docs
- tflint

### Language Run-times

- Golang version manager
- Python / Pip

## Usage

### WARNING

- System packages managed by `apt` or `yum` will be installed / updated to the latest version on every execution.
- Toolchain packages will be replaced with the version defined in `${PROJECT_ROOT}/libs/bash/versions.sh` when `--update true` argument is provided.

### Install

```sh
git clone [project URL]
```

### Usage

Take from ./libs/bash/install.sh header section.

```sh
# Example usage:

./libs/bash/install.sh
./libs/bash/install.sh --arch amd64 --platform darwin
./libs/bash/install.sh --arch amd64 --platform darwin --update true
./libs/bash/install.sh --arch arm32 --platform linux
./libs/bash/install.sh --arch arm32 --platform linux --shell_profile "$HOME/.zshell_profile"
./libs/bash/install.sh --arch arm32 --platform linux --skip_misc_tools true
./libs/bash/install.sh --bin_dir "/usr/bin" --skip_aws_tools true --update true
./libs/bash/install.sh --skip_aws_tools true --update true
./libs/bash/install.sh --skip_system_tools true --skip_terraform_tools true --skip_misc_tools true
```

### Update Toolchain

```sh
./libs/bash/install.sh --update true
```

Note: `--skip_*_tools` and `--update` can be used together to update specific tool groups

## Development

Start a shell session at the root of the project. Then set the required default ENV VARs.

```sh
ALTARCH="x86_64"
ARCH="amd64"
BIN_DIR="/usr/local/bin"
PLATFORM="linux"
PROJECT_ROOT=$(git rev-parse --show-toplevel)
SHELL_PROFILE="$HOME/.worldline_pps_profile"
UPDATE="false"
WL_GC_TM_WORKSPACE=$(git rev-parse --show-toplevel)

source "$PROJECT_ROOT/libs/bash/versions.sh"
```

Now you should be ready to run all the commands manually.

## Additional Information

- Adding visual aids to any / all the above sections above is recommended.
- [ROADMAP](./ROADMAP.md) example from [all-contributors/all-contributors](https://github.com/all-contributors/all-contributors/blob/master/MAINTAINERS.md).
- Based on [README Maturity Model](https://github.com/LappleApple/feedmereadmes/blob/master/README-maturity-model.md); strive for a Level 5 `Product-oriented README`.

