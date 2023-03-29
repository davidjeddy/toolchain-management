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

## [0.10.0] - 2023-03-15

NOTE: This version required the removal of configuration in ~/.bash_profile if using previous versions.

- FIXED `goenv` install process
- - UPDATED SHELL_PROFILE to use ~/.worldline_pps_profile

## [0.9.0] - 2023-02-01 - Unreleased

- Everything before 0.10.0
