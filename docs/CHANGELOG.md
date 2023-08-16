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

## [0.19.0] - 2023-08-11

- ADDED `trivy`
- REMOVED `trivy`
- UPDATED all other tools to latest release version

## [0.18.0] - 2023-07-31

- ADDED `podman`` to system tool for YUM (Fedora, RHEL)
- ADDED timeout() to pipeline to trigger failure after 15mins
- ADDED global var gitlab ConnectionName to Jenkinsfile
- ADDED Slack notification when build is `fixed`

## [0.17.0] - 2023-07

- ADDED podman system tool for APT systems

## [0.16.0] - 2023-07

- ADDED xeol system tool

## [0.15.0] - 2023-07

- ADDED parallel system tool

## [0.11.0] - 2023-06-08

- FIXED incorrect var reference to eval to install AWS CLI
- ADDED eval for Fedora vs Red Hat in system tool install

## [0.10.0] - 2023-03-15

NOTE: This version required the removal of configuration in ~/.bash_profile if using previous versions.

- FIXED `goenv` install process
- - UPDATED SHELL_PROFILE to use ~/.worldline_pps_profile

## [0.9.0] - 2023-02-01 - Unreleased

- Everything before 0.10.0
