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

Collection of resources and tools used to manage IAC projects.

## Purpose

Ensure compliance with community and securitybest practices via the shift-left pattern. This enables the presenting violations regarding organizational auditing, linting, security, and style guides as soon as an engineer attempts to save code. Additionally, toolchain has to ability to enforce the version of the tools installed. Ensure the engineering teams can stay up to date without messing around updating each to individually.

Currently only localhost Fedora VM/QEMU and Jenkins RHEL pipeline tools are supported. 

Engineer commits change to localhost git project -> toolchain triggered (pre-commit hook) -> scanning tools execute -> if violations are found, the save is aborted

## Requirements / Supported Platforms

- [Fedora](https://fedoraproject.org/)(recommended) or [RHEL](https://en.wikipedia.org/wiki/Red_Hat_Enterprise_Linux)(second option) based are the only distributions currently supported
  - UTM / [Installing Fedora Workstation 39 QEMU via UTM on DWS Apple M2 MacBook Pro](https://confluence.worldline-solutions.com/display/PPSTECHNO/Installing+Fedora+Workstation+38+on+DWS+Apple+M2+MacBook+Pro)
  - VirtualBox / [Installing Fedora Workstation 38 Virtual Machine on DWS Workstation](https://confluence.techno.ingenico.com/display/PPS/Installing+Fedora+Workstatio+38+Virtual+Machine+on+DWS+Workstation)
- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) >= 5.x
- [Git](https://git-scm.com/) >= 2.x

## Tools Includes (but are not limited to)

### AWS

- AWS CLI
- iam-policy-json-to-terraform (x86)

### Terraform

- Checkov
- Infracost
- KICS
- Terraform version manager
- Terragrunt version manager
- tf-docs
- tflint

### Language Run-times

- Golang
- Python

## Usage

### WARNING

- System packages managed by `apt` or `yum` will be installed / updated to the latest version on every execution.
- Toolchain managed packages will be replaced with the version defined in `${PROJECT_ROOT}/libs/bash/versions.sh` when `--update true` argument is provided.

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
./libs/bash/install.sh --arch aarch64
./libs/bash/install.sh --arch aarch64 --shell_profile "$HOME/.zshell_profile"
./libs/bash/install.sh --arch aarch64 --platform linux --skip_misc_tools true
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
ARCH="aarch64"
BIN_DIR="/usr/local/bin"
PLATFORM="linux"
PROJECT_ROOT=$(git rev-parse --show-toplevel)
SHELL_PROFILE="$HOME/.worldline_pps_profile"
UPDATE="false"
WL_GC_TM_WORKSPACE=$(git rev-parse --show-toplevel)

source "$PROJECT_ROOT/libs/bash/versions.sh"
```

Now you should be ready to run all the commands manually.

## Testing on localhost

These are the `stage` commands the Jenkinsfile will run, minus tagging.

```sh
./libs/bash/install.sh --skip_cloud_tools true --skip_misc_tools true --skip_iac_tools true --update true --skip_system_tools true
./libs/bash/install.sh --skip_misc_tools true --update true
./libs/bash/install.sh --skip_cloud_tools true --skip_misc_tools true --skip_iac_tools true --update true
./libs/bash/install.sh --skip_misc_tools true --skip_iac_tools true --skip_system_tools true --update true
./libs/bash/install.sh --skip_cloud_tools true --skip_misc_tools true --skip_system_tools true --update true
./libs/bash/install.sh --skip_misc_tools true
```

## Versioning

This project follows [SemVer 2.0](https://semver.org/).

```quote
Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when you make incompatible API changes,
2. MINOR version when you add functionality in a backwards compatible manner, and
3. PATCH version when you make backwards compatible bug fixes.

Additional labels for pre-release and build metadata are available as extensions to the MAJOR.MINOR.PATCH format.
```

## Contributors

## Additional Information

- Adding visual aids to any / all the above sections above is recommended.
- Based on [README Maturity Model](https://github.com/LappleApple/feedmereadmes/blob/master/README-maturity-model.md); strive for a Level 5 `Product-oriented README`.
- Additional documentation available in [./docs/](./docs/).