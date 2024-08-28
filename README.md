# Toolchain Management

## Table of Contents

- [Toolchain Management](#toolchain-management)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Purpose](#purpose)
  - [Requirements / Supported Platforms](#requirements--supported-platforms)
  - [Tools List](#tools-list)
  - [Usage](#usage)
    - [WARNING](#warning)
    - [Install](#install)
    - [Update](#update)
    - [Upgrade From \< 0.50.0 to \>= 0.50.0](#upgrade-from--0500-to--0500)
  - [Versioning](#versioning)
  - [Contributors](#contributors)
  - [Additional Information](#additional-information)

## Description

Collection of resources and tools used to manage IAC projects.


## Purpose

To ensure compliance with community and security best practices via the shift-left pattern. This enables the presenting violations regarding organizational auditing, linting, security, and style guides as soon as an engineer attempts to save code. Additionally, toolchain has to ability to enforce the version of the tools installed. Ensure the engineering teams can stay up to date without messing around updating each to individually.

Currently only localhost Fedora VM/QEMU and Jenkins RHEL pipeline tools are supported.

Engineer commits change to localhost git project -> toolchain triggered (pre-commit hook) -> scanning tools execute -> if violations are found, the save is aborted

## Requirements / Supported Platforms

- [Fedora](https://fedoraproject.org/)(recommended) or [RHEL](https://en.wikipedia.org/wiki/Red_Hat_Enterprise_Linux)(second option) based systems are the only distributions currently actively supported
  - UTM / [Installing Fedora Workstation 39 QEMU via UTM on DWS Apple M2 MacBook Pro](https://confluence.worldline-solutions.com/display/PPSTECHNO/Installing+Fedora+Workstation+38+on+DWS+Apple+M2+MacBook+Pro)
  - VirtualBox / [Installing Fedora Workstation 38 Virtual Machine on DWS Workstation](https://confluence.techno.ingenico.com/display/PPS/Installing+Fedora+Workstatio+38+Virtual+Machine+on+DWS+Workstation)
- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) >= 5.x
- [Git](https://git-scm.com/) >= 2.x

## Tools List

For a complete list of tools provided please view ./aqua.yml, ./libs/bash/additional_tools.sh, ./libs/bash/language_runtimes.sh, ./libs/bash/system_tools.sh, and ./versions.sh

## Usage

### WARNING

- OneLogin-AWS-CLI is NOT installed on `apk` based systems as the running container will have permissions based on IAM Task Role permissions
- System packages managed by `apt`, `dnf`, or `yum` will be installed / updated to the latest version on every execution.

### Install

```sh
cd /path/to/projects
git clone ...
cd toolchain-management
./libs/bash/install.sh
source ~/.bashrc
```

### Update

Unlike the <= 0.50.0 release family of this project, it is no longer needed to pass CLI arguments to update the tools. Simply change the desired version number in `aqua.yaml`, `.*-version` or `VERSIONS.sh`. Then re-run the `./libs/bash/install.sh` to update tooling.

### Upgrade From < 0.50.0 to >= 0.50.0

Note: This process only needs to be executed only once.

**MAKE A BACKUP of your OS (VM/etc)! This process involves deleting configurations, binaries, and language interpreters.**

If, like me, you want to keep you system as clean as possible execute the following before running the installer of >= 0.50.0

First, remove all references to goenv, pyenv, aqua, and .worldline_pps_* files.

```sh
vi ~/.bashrc
vi ~/.bash_profile
# ... and any other shell profile configurations that may container references to toolchain configuration
source ~/.bashrc
```

Next, remove group shell configuration and language runtimes

```sh
rm -rf ~/.goenv/ || true
rm -rf ~/.pyenv/ || true
rm ~/.worldline_pps_* || true
```

Third, remove all pre-upgrade managed tools

```sh
sudo su

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
yes | rm -rf /usr/local/bin/localstack* || true
yes | rm -rf /usr/local/bin/pip3* || true
yes | rm -rf /usr/local/bin/pydoc3* || true
yes | rm -rf /usr/local/bin/python3* || true

exit # return back to normal user
```

To verify we are now in good shape, list the contains of `/usr/local/bin`

```sh
ls -lah /usr/local/bin
```

No IAC, Golang, nor Python (3.x) binaries or directories should be listed.

Finally, execute the installation process.

```sh
./libs/bash/install.sh
source ~/.bashrc
```

With that the upgrade process is complete. Tools managed by Aqua should be available globally and at the version defined in `.aqua.yaml`.

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
