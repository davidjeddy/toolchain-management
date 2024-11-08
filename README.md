# Toolchain Management

## Table of Contents

- [Toolchain Management](#toolchain-management)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Important Notes](#important-notes)
  - [Purpose](#purpose)
  - [Requirements / Supported Platforms](#requirements--supported-platforms)
  - [Tools List](#tools-list)
  - [Usage](#usage)
    - [Install](#install)
    - [Pipeline](#pipeline)
    - [Update](#update)
  - [Options](#options)
  - [Versioning](#versioning)
  - [Contributors](#contributors)
  - [Additional Information](#additional-information)

## Description

Collection of packages and tools used to manage projects.

## Important Notes

- Language versions (Python, Golang, etc) are managed via the system package manager (>= 0.60.0)
  - We do NOT want to abstract this to a *env helper. Replace the host, not the language version.
- If you are running on [Windows using WSL2](https://confluence.worldline-solutions.com/display/PPSTECHNO/WSL2+Host):
  - You MUST clone the project from INSIDE the WSL instance. NOT from the host Windows.
  - AFTER the Toolchain installation completes successfully, also execute the following to enable onelogin usage: `pip install keyring 25.4.1 && pip install keyrings.alt 5.0.2` 

## Purpose

To ensure compliance with community and security best practices via the shift-left pattern. This enables the presenting violations regarding organizational auditing, linting, security, and style guides as soon as an engineer attempts to save code. Additionally, toolchain has to ability to enforce the version of the tools installed. Ensure the engineering teams can stay up to date without messing around updating each to individually.

## Requirements / Supported Platforms

- [Fedora](https://fedoraproject.org/)(recommended) or [RHEL](https://en.wikipedia.org/wiki/Red_Hat_Enterprise_Linux)(second option) based systems are the only distributions currently actively supported
  - UTM / [Installing Fedora Workstation 39 QEMU via UTM on DWS Apple M2 MacBook Pro](https://confluence.worldline-solutions.com/display/PPSTECHNO/Installing+Fedora+Workstation+38+on+DWS+Apple+M2+MacBook+Pro)
  - [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)
- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) >= 5.x
- [Git](https://git-scm.com/) >= 2.x

## Tools List

For a complete list of tools provided please view the .*-version- files.

## Usage

### Install

```sh
cd /path/to/projects
git clone ...
cd toolchain-management
./libs/bash/install.sh
# start new shell session
```

### Pipeline

- Jenkins pipeline should only be run on EC2 hosts
- ECS hosts should have container image build and deployed with the Toolchain version pre-installed

### Update

Simply change the desired version number in the .*-version- file and re-run the install script.

## Options

Environmental variable overrides:

- LOG_LEVEL="TRACE" Enable BASH shell command outputting to see every command being executed
- SESSION_SHELL="$HOME/.some_shell_config" allows for overriding .bashrc as the default session shell configuration

Skip this section of the install process (may have unintended side effects):

- WL_GC_TOOLCHAIN_ASDF_SKIP=true
- WL_GC_TOOLCHAIN_ASDF_TOOLS_SKIP=true
- WL_GC_TOOLCHAIN_IAC_TOOLS_SKIP=true
- WL_GC_TOOLCHAIN_JAVA_TOOLS_SKIP=true
- WL_GC_TOOLCHAIN_PYTHON_TOOLS_SKIP=true
- WL_GC_TOOLCHAIN_ROOT_OVERRIDE=true
- WL_GC_TOOLCHAIN_SYSTEM_TOOLS_SKIP=true

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

