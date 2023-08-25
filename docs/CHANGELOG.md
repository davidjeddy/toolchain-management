# CHANGELOG

## References

- [keep a changelog](https://keepachangelog.com/en/1.0.0/)

[[ACTION]] [[Service]] [[Description]]

Action Keywords:

`ADDED`  : Functionality did not exist previously.
`FIXED`  : Functionality existed but did not behave as expected.
`REMOVE` : Functionality is no longer available.
`UPDATED`: Functionality capability expanded with additional abilities.

## [TODO]

ADD AWS CLI SSM plugin

- https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-linux
- build from source due to binary packages not following the wider community naming convention
- https://github.com/aws/session-manager-plugin/archive/refs/tags/1.2.463.0.tar.gz
- Add additional container tools such as containerd, dive, kubtctl, etc
- Add PGP checking for binaries that make it available

## [0.20.0] - 2023-08-25

### Added

- ./libs/bash/bambora_onelogin_aws.sh

### FIXED

- ./docs/CHANGELOG.md formatting

## [0.19.0] - 2023-08-11

### Added

- trivy

### Fixed

- all other tools to latest release version

### Removed

- tfsec

## [0.18.0] - 2023-07-31

### Added

- `podman`` to system tool for YUM (Fedora, RHEL)
- timeout() to pipeline to trigger failure after 15mins
- global var gitlab ConnectionName to Jenkinsfile
- Slack notification when build is `fixed`

## [0.17.0] - 2023-07

### Added

- podman system tool for APT systems

## [0.16.0] - 2023-07

### Added

-  xeol system tool

## [0.15.0] - 2023-07

### Added

-  parallel system tool

## [0.11.0] - 2023-06-08

### Added

- eval for Fedora vs Red Hat in system tool install

### Fixed

- incorrect var reference to eval to install AWS CLI

### Removed

## [0.10.0] - 2023-03-15

### Added

- Everything before 0.10.0 lost to the sands of time

### Fixed

- `goenv` install process
- SHELL_PROFILE to use ~/.worldline_pps_profile
  - NOTE: This version required the removal of configuration in ~/.bash_profile if using previous versions.

### Removed

## [0.7.0]

## [0.6.0]

## [0.5.0]
