# CHANGELOG

## References

- [keep a changelog](https://keepachangelog.com/en/1.0.0/)

[[ACTION]] [[Service]] [[Description]]

Action Keywords:

`ADDED`   : Functionality did not exist previously.
`FIXED`   : Functionality existed but did not behave as expected.
`REMOVED` : Functionality is no longer available.

## [0.37.1] - 2024-02-15

### FIXED

- Missing URL in failure notification in Jenkinsfile

## [0.37.0] - 2024-02-13

### ADDED

- [containers/skopeo](https://github.com/containers/skopeo) to replace Worldline container-image-mirror be-spok solution in the near future
- Ability to override the toolchain project branch from downstream projects via `./libs/bash/git/install.sh`

### FIXED

- pre-commit and pre-push process to prevent race condition regardng sbom.xml generation and appending to commits

## [0.36.2] - 2024-02-13

## FIXED

- Incorrect Container id extracted from task detail, leading failure of db port forwarding from ecs task

## [0.36.1] - 2024-02-09

### ADDED

- Jenkins triggers.pollSCM to ensure deleted/merged branches are removed from Jenkins daily

## [0.36.0] - 2024-02-01

### FIXED

- Reworked pre-* git hooks to work better with automation tools

## [0.35.2] - 2024-01-31

## FIXED

- Incorrect exit code when no changes to IAC code

## [0.35.1] - 2024-01-31

## FIXED

- Git hooks should have the ability to be executed

## [0.35.0] - 2024-01-29

## ADDED

- pre-push git hook to ensure feature branch compliance before review is created

## FIXED

- pre-commit compliance checks now only diff against the previous commit

## [0.34.3] - 2024-01-29

## Added

- `cat` the contents of an error file when IaC compliance tools fail in `pre_commit_function.sh`

## [0.34.2] - 2024-01-25

## Added

- TLS cipher check helper script

## [0.34.1] - 2024-01-19

## Addd

- check for KICS query library during pre-commit execution

## Fixed

- spelling error

## [0.34.0] - 2024-01-18

## Addd

- [tofuenv](https://github.com/tofuutils/tofuenv) to manage versions of [OpenTofu](https://opentofu.org/)

## [0.33.1] - 2024-01-17

### Fixed

- syntax error in `libs/bash/aws/ecs_update_service_task.sh`

## [0.33.0] - 2024-01-17

### Fixed

- `libs/bash/aws/ecs_update_service_task.sh` to ignore active* and hazelcast* named services

### Removed

- `libs/bash/aws/cycle_modules.sh` as duplicate of `libs/bash/aws/ecs_update_service_task.sh`

## [0.32.22] - 2023-12-12

### Fixed

- do not execute goenv install during normal operation; only during install and force update operations
- check got onelogin-aws-login binary from pip onelogin-aws-cli package
- generic `terraform` references with `iac` in both filenames and function invocations
- Groovy linting issues in Jenkinsfile
- `$HOME` replaced with `~` to enable fully expanding path and glob expressions
- goenv no longer outputs progress bar when installing go version

## [0.32.21] - 2023-12-11

### Fixed

- checkov now only scans the directly it is initilaized in, no more sub-directory recursive scanning

## [0.32.20] - 2023-12-11

### Fixed

- xeol should not yet bet enabled

## [0.32.19] - 2023-12-11

### Fixed

- comment that should not be un-charactered

## [0.32.18] - 2023-12-11

### Fixed

- checkov version addressing upstream dep error

## [0.32.17] - 2023-12-07

### Fixed

- Refactored helper scripts to avoid console printing of execution steps

## [0.32.16] - 2023-12-11

### Removed

- checkov dependencies in toolchain until checkov release new version fixing broken cyclondx version dep

## [0.32.15] - 2023-11-20

### Fixed

- the ability to select the container withini an ECS task using ./libs/bash/aws/ecs_task_shell_connection.sh

## [0.32.14] - 2023-11-20

### Fixed

- missing process to install tfsec

## [0.32.14] - 2023-11-20

### Fixed

- Mon-Fri daily scheduled execution to prevent conflict with IaC shared module daily executions

## [0.32.13] - 2023-11-17

### Fixed

- Another pass at SEMVER extraction from CHANGELOG diff

## [0.32.12] - 2023-11-16

### Fixed

- Testing tagging stage operation

## [0.32.11] - 2023-11-16

### Fixed

- Replace HEAD~1 with fetch and origin/main

## [0.32.10] - 2023-11-16

### Fixed

- pre_commit.sh git diff checker now fetches and uses origin/main as the target

## [0.32.9] - 2023-11-16

### Fixed

- `t*env install *` only if version not already available
- output README if diff exists in pipeline
- SEM_VER extraction regex
- update checkov version to 3.x release

## [0.32.8] - 2023-11-15

### Fixed

- increate pipeline timeout from 15 mins to 30 mins to account for when Python needs to be compiled

## [0.32.7] - 2023-11-15

### Fixed

- tflint usage with shared modules

## [0.32.6] - 2023-11-15

### Fixed

- pathing error leading to KICS query library

## [0.32.5] - 2023-11-14

### Fixed

- replaced missing escape character in ./libs/jenkins/pipelines/vars/SharedModule.groovy regex when dealing with CHANGELOG parsing.

## [0.32.4] - 2023-11-14

### Fixed

- errant space in ./libs/jenkins/pipelines/vars/SharedModule.groovy regex when dealing with CHANGELOG parsing.

## [0.32.3] - 2023-11-14

### Fixed

- changed `fixed` pipeline emoji from :alert: to :tada:
- spelling error in pre_commit_functions.sh

## [0.32.2] - 2023-11-13

### Fixed

- pathing in pre_commit

## [0.32.1] - 2023-11-10

### Added

- issue wherein the Tag was not being created, we needed `HEAD~1` not `main` as the target to `diff` against

## [0.32.0] - 2023-11-06

### Added

- Shared pipeline for use by Worldline IaC shared modules

## [0.31.6] - 2023-11-06

### Fix

- Go and Python install processes updated to better handle newly created hosts

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
