# Toolchain Management

## Table of Contents

- [Toolchain Management](#toolchain-management)
  - [Table of Contents](#table-of-contents)
  - [Badges](#badges)
  - [Description](#description)
  - [WARNING](#warning)
  - [Purpose](#purpose)
  - [Requirements](#requirements)
  - [Usage](#usage)
    - [Install](#install)
    - [Usage](#usage-1)
    - [Update Toolchain](#update-toolchain)
  - [Development](#development)
  - [Additional Information](#additional-information)

## Badges

Build Status, Code Coverage, PR stats/time frame, Project status, etc.

## Description

Collection of resources used to manage Terraform related tools.

## WARNING

- System packages managed by `apt` or `yum` will be installed / updated to the latest version on every execution.
- Toolchain packages will be replaced with the version defined in `./libs/bash/versions.sh` when `--update true` argument is provided.

## Purpose

Ensure compliance, consistency, and quality in Terraform projects.

## Requirements

- [Linux](https://en.wikipedia.org/wiki/Linux) (kernal >= 4.x)
  - `sudo` ability
  - [Debian](https://en.wikipedia.org/wiki/Debian) or [RHEL](https://en.wikipedia.org/wiki/Red_Hat_Enterprise_Linux) based are the only distributions currently supported
- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) >= 5.x
- [Git](https://git-scm.com/) >= 2.x

## Usage

### Install

```sh
git clone [project URL]
```

### Usage

Take from ./libs/bash/run.sh header section.

```sh
# Example usage:

./libs/bash/run.sh
./libs/bash/run.sh --arch amd64 --platform darwin
./libs/bash/run.sh --arch amd64 --platform darwin --update true
./libs/bash/run.sh --arch arm32 --platform linux
./libs/bash/run.sh --arch arm32 --platform linux --shell_profile "$HOME/.zshell_profile"
./libs/bash/run.sh --arch arm32 --platform linux --skip_misc_tools true
./libs/bash/run.sh --bin_dir "/usr/bin" --skip_aws_tools true --update true
./libs/bash/run.sh --skip_aws_tools true --update true
./libs/bash/run.sh --skip_system_tools true --skip_terraform_tools true --skip_misc_tools true
```

### Update Toolchain

```sh
./libs/bash/run.sh --update true
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

source "$PROJECT_ROOT/libs/bash/versions.sh"
```

Now you should be ready to run all the commands manually.

## Additional Information

- Adding visual aids to any / all the above sections above is recommended.
- [ROADMAP](./ROADMAP.md) example from [all-contributors/all-contributors](https://github.com/all-contributors/all-contributors/blob/master/MAINTAINERS.md).
- Based on [README Maturity Model](https://github.com/LappleApple/feedmereadmes/blob/master/README-maturity-model.md); strive for a Level 5 `Product-oriented README`.

