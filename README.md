# Toolchain Management

## Table of Contents

- [Toolchain Management](#toolchain-management)
  - [Table of Contents](#table-of-contents)
  - [Badges](#badges)
  - [Description](#description)
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

## Purpose

Ensure compliance, consistency, and quality in Terraform projects.

## Requirements

- [Linux](https://en.wikipedia.org/wiki/Linux) (kernal >= 4.x)
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
# usage ./libs/bash/run.sh PLATFORM ARCH SHELLRC
# example ./libs/bash/run.sh
# example ./libs/bash/run.sh --arch arm32 --platform linux
# example ./libs/bash/run.sh --arch amd64 --platform darwin
# example ./libs/bash/run.sh --arch arm32 --platform linux --shellrc $HOME/.bashrc
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
