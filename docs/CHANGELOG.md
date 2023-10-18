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

- Migrate to a community supported tool, this be-spoke solution is not a long term solution
- build from source binary packages that do not following the wide community naming convention
- Add additional container tools such as containerd, dive, kubtctl, etc
- Add PGP checking for all binaries that make it available
- Add the ability to install the toolchain once, globally per user, instead of per-project

## [0.31.5] - 2023-10-18

### Added

- `cleanWs()` to `clean workspace` stage
- interactive and non-interactive shells loading additional configuration from $SHELL_PROFILE

### Fixed

- pip must be installed BEFORE `pip install cmake` can be executed

## [0.31.4] - 2023-10-17

### Fixed

- Daily running of the pipeline now works only for main branch so installed software isn't corrupted when installed in parallel

## [0.31.3] - 2023-09-28

### Fixed

- Added output during KICS build to indicate possible issues with proxy/firewall blocking git(ssh)

## [0.31.2] - 2023-09-21

### Fixed

- Added equal(=) sign in `tree --sort` to support debian OS tree package
- Added `tail` and `head` command to remove first and last lines of tree command, avoiding execution of non terraform directories
- Fixed `apply` log file name ISO `plan`

## [0.31.1] - 2023-09-18

### Fixed

- Pathing to common/get_cmd_options.sh when using ./libs/bash/aws helpers

## [0.31.0] - 2023-09-04

### Fixed

- Added 'tree' install via to system_tools package managers
- Added script to execute IAc lifecycle across a deployments entire ecs-services sub-modules

## [0.30.0] - 2023-09-04

### Fixed

- ./libs/bash/* to better support a wide range of vendor helper scripts

## [0.26.0] - 2023-09-04

### Added

- ./libs/jenkins/terraform/Jenkinsfile to begin to reduce copy/paste across all the Connect 2 Cloud IaC modules

## [0.25.0] - 2023-08-31

### Added

- [AWS CLI SSM plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- Note regarding Python 3.x version due to host limitations

### Fixed

- Directory path to git pre-commit scripts for use by downstream projects

## [0.24.0] - 2023-08-29

### Fixed

-Fixed installation of trivy package by putting current path prefix
-Removed unwanted packages(ca-certification, gnupg2, wget) installation from apt-systems
-Added gnupg2 package installation for Fedora and Red Hat

## [0.23.0] - 2023-08-28

### Added

-Added script to install trivy
-Added script to install podman and builah for debian

## [0.22.0] - 2023-08-28

### Added

- ./libs/bash/bambora_onelogin_Aws.sh to decrease authentication effort

## [0.21.0] - 2023-08-28

### Added

- ./libs/bash/install_toolchain_management.sh as a shared resource for IaC module installation

### Fix

- ./libs/bash/install.sh reverted to install process for project

## [0.20.0] - 2023-08-25

### Added

- ./libs/bash/bambora_onelogin_aws.sh

### FIXED

- ./docs/CHANGELOG.md formatting

## [0.19.0] - 2023-08-11

### Added

- trivy for yum based systems

### Fixed

- all other tools to latest release version

### Removed

- tfsec

## [0.18.0] - 2023-07-31

### Added

- `podman` to system tool for YUM (Fedora, RHEL)
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
