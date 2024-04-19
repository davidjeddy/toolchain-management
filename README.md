# Toolchain Management

## Table of Contents

- [Toolchain Management](#toolchain-management)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Purpose](#purpose)
  - [Requirements / Supported Platforms](#requirements--supported-platforms)
  - [Tools Includes (but are not limited to)](#tools-includes-but-are-not-limited-to)
    - [AWS](#aws)
    - [Terraform / OpenTofu](#terraform--opentofu)
    - [Language Run-times](#language-run-times)
  - [Usage](#usage)
    - [WARNING](#warning)
    - [Install](#install)
    - [Invoke](#invoke)
    - [Update](#update)
  - [Versioning](#versioning)
  - [Contributors](#contributors)
  - [Additional Information](#additional-information)

## Description

Collection of resources and tools used to manage IAC projects.

## Purpose

Ensure compliance with community and security best practices via the shift-left pattern. This enables the presenting violations regarding organizational auditing, linting, security, and style guides as soon as an engineer attempts to save code. Additionally, toolchain has to ability to enforce the version of the tools installed. Ensure the engineering teams can stay up to date without messing around updating each to individually.

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

### Terraform / OpenTofu

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

- System packages managed by `apt`, `dnf`, or `yum` will be installed / updated to the latest version on every execution.

### Install

```sh
cd /path/to/projects
git clone ...
cd toolchain-management
```

### Invoke

```sh
./libs/bash/install.sh
source ~/.bashrcaa
```

### Update

Unlike the <= 1.x release of this project, it is no longer needed to pass CLI arguments to update the tools. Simply change the desired version number in `aqua.yaml`, `.*-version` or `VERSIONS.sh`. Then re-run the `./libs/bash/install.sh` to update a tool.

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