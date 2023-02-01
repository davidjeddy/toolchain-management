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
    - [Change / Update](#change--update)
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

```sh
# See the header of ./libs/bash/run.sh for more advanced install options
./libs/bash/run.sh
```

### Change / Update

```sh
./libs/bash/run.sh --update true
```

## Additional Information

- Adding visual aids to any / all the above sections above is recommended.
- [ROADMAP](./ROADMAP.md) example from [all-contributors/all-contributors](https://github.com/all-contributors/all-contributors/blob/master/MAINTAINERS.md).
- Based on [README Maturity Model](https://github.com/LappleApple/feedmereadmes/blob/master/README-maturity-model.md); strive for a Level 5 `Product-oriented README`.
