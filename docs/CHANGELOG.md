# CHANGELOG

## References

- [keep a changelog](https://keepachangelog.com/en/1.0.0/)

[[ACTION]] [[Service]] [[Description]]

Action Keywords:

- `ADD`   : Functionality did not exist previously.
- `FIX`   : Functionality existed but did not behave as expected.
- `REMOVE` : Functionality is no longer available.

## [0.57.1] - 2024-09-05

### FIX

- Minor cleanup of the install.sh

### REMOVE

- LocalStack from installation via PIP on Red Hat 7 hosts or NOT jenkins / root user due to install requirements

## [0.57.0] - 2024-09-05

### FIX

- Should source `common.sh` before calling the `autoUpdate()`

## [0.57.0] - 2024-09-04

### ADD

- `./libs/bash/reset.sh` to assist in cleaning localhost for clean re/installation
- `options` section to the README.md
- ability to skip additiona, aqua, iac, lanugage, and system tools using ENV VAR
- if `SESSION_SHELL` file does not exist, we now create it
- Missing `setuptools` Python package
- noted when `apt` (Debian/Ubuntu) and `yum` (RHEL) support will be removed from system tools
- sonar-scanner CLI to `additional_tools.sh`
- SonarQube `sonar-scanner` to additonal tools
- wrapped `autoUpdate()` in an ENV VAR to enable disablement

### FIX

- `additional_tools.sh` now install into `/usr/bin` to align better with containerized workloads
- `autoUpdate()` logic to properly check localhost version VS remote version
- Do not install system tools if `sudo` is not available (typically in containers)
- Helper scripts now properly source `source "$SESSION_SHELL"` not `$HOME/.bashrc`
- Localstack now installed via Pythons package manager `pip` like other Python packages
  - To note: We install `localstack[runtime]` is the user is jenkins or root. This is to ensure functionality on container hosted instances of localstack
  - [The initial install can take a long time due to PIP package version resolving](https://github.com/localstack/localstack/blob/master/requirements-runtime.txt)
- Python packages now managed by PIP and `requirements.txt`
- Python updated to version 3.12.5

### REMOVED

- `apk` evaluations, no longer using Alpine. Lets stick w/ Fedora for consistance

## [0.55.6] - 2024-09-04

### FIX

- Comparison operation in Blast radius constraint function

## [0.55.5] - 2024-09-03

### ADD

- Blast radius constraint function that limits change sets to a single IAC deployments (terraform/aws/[[ACCT]]/[[REGION]]/[[APP/SRV]])

## FIX

- `./libs/bash/git/hooks/pre-*` by moving the functions to `./libs/bash/git/common.sh`

## [0.55.4] - 2024-08-28

### FIX

- `./libs/bash/additional_tools.sh` once again installs AWS SessionManagerPlugin per OS/Arch as desired
- `curl` invocations in `./libs/bash/additional_tools.sh` now includes `--verbose`

## [0.55.3] - 2024-08-27

### FIX

- `./libs/bash/auth/onelogin_bambora_aws.sh` to once again function as desired
  
## [0.55.2] - 2024-08-12

### FIX

- `bash: pyenv: command not found...` after clean install

## [0.55.1] - 2024-08-07

### FIX

- migrate from ~/.bashrc to $HOME/.bashrc due to ~/ not expanding to the full path on some systems
- pyenv failing to install properly due to ~/.bashrc not being interprited correctly
- Stop putting the start/end indicators into ~/.bashrc repeatidly
- Start/Stop lines in ~/.bashrc changed to be more descriptive of the owner

## [0.55.0] - 2024-08-06

### FIX

- Can now be used with Alpine (apk) based containers / systems

## [0.54.39] - 2024-08-05

### FIX

- `./libs/jenkins/pipelines/vars/SharedModule.groovy` steps shell invocation better aligned with helper scripts

## [0.54.38] - 2024-08-03

### FIX

- Do not try to install Python/PIP related resources on APK based hosts

## [0.54.37] - 2024-08-02

### ADD

- helper script to execute IAC lifecycle on child dir

### FIX

- Do not fail when system package manager is not found, enable executing in Alpine based containers

## [0.54.36] - 2024-08-02

### ADD

- `./libs/bash/git/delete_old_branches.sh` to prune stale/abandoned branches

### FIX

- `./libs/bash/aws/backup_delete_all_recovery_points.sh` file mode
- Version bumped some tools
- Version output of TF anf TG reading from incorrect files

## [0.54.34] - 2024-08-01

### FIX

- Jenkinsfile update

## [0.54.33] - 2024-07-30

### FIX

- `./libs/bash/git/hooks/pre-push` to rebase from origin/main to ensure compliance and security scans execute correctly

## [0.54.33] - 2024-09-03

### ADD

- Blast radius constraint function that limits change sets to a single IAC deployments (terraform/aws/[[ACCT]]/[[REGION]]/[[APP/SRV]])

## FIX

- `./libs/bash/git/hooks/pre-*` by moving the functions to common.sh; now the pre-* hook sscripts are once again nearly identical

## [0.54.32] - 2024-07-25

### FIX

- Method calls on objects not allowed outside "script" blocks.

## [0.54.31] - 2024-07-24

### FIX

- Working on CODEOWNER feature enablement

## [0.54.30] - 2024-07-24

### FIX

- `libs/bash/git/install.sh` no longer updates itself causing errors in the process 

## [0.54.29] - 2024-07-24

### FIX

- libs/jenkins/pipeline/vars/SharedModule.groovy logRotator now uses Groovy List for configuration
- Working on CODEOWNER feature enablement

## [0.54.28] - 2024-07-24

### FIX

- Working on CODEOWNER feature enablement

## [0.54.27] - 2024-07-24

### FIX

- Working on CODEOWNER feature enablement

## [0.54.26] - 2024-07-24

### FIX

- Working on CODEOWNER feature enablement

## [0.54.25] - 2024-07-24

### FIX

- Working on CODEOWNER feature enablement

## [0.54.25] - 2024-07-24

### ADD

- ./CODEOWNER to scope who can approve merge requests
- ./libs/bash/aws/backup_delete_all_recovery_points.sh to remove recovery points from AWS Backup Plan

## [0.54.24] - 2024-07-19

### FIX

- Removed `grep "terraform/aws/"` from filtering out `generateDiffList()` output - it caused shared modules projects to skip most of the pre-commit logic

## [0.54.23] - 2024-07-18

### FIX

- `./libs/bash/git/hooks/pre-commit` autoautoUpdate() was not properly getting tags for toolchain project

## [0.54.22] - 2024-07-17

### FIX

- `./libs/bash/git/hooks/pre-commit` syntax error

## [0.54.21] - 2024-07-16

### ADD

- `./libs/bash/git/install.sh` to auto-update toolchain as an upstream project if the localhost version does not match the latest in the remote host

## [0.54.23] - 2024-07-15

### FIX

- Logging level VAR changed to generic `LOG_LEVEL`
- Verbosity output of Bash scripts, leveraging ENV VAR `LOG_LEVEL`

## [0.54.22] - 2024-07-15

### ADD

- [localStack-cli](https://github.com/localstack/localstack-cli) via additional_tools.sh
- [Maven (mvn)](https://github.com/apache/maven-mvnd) via additional_tools.sh
- [Maven daemon (mvnd)](https://github.com/apache/maven-mvnd) via Aqua

### REMOVE

- Errant creation of `slack` object in `./libs/bash/jenkins/pipelines/vars/SharedModule.groovy`, the object is passed in from the calling pipeline

## [0.54.21] - 2024-07-15

### FIX

- Force the loading of `~/.bashrc` on every `./libs/bash/common/*.sh` helper script
- Force the loading of `~/.bashrc` on every `./libs/bash/git/**/*.sh` helper script
- Force the loading of `~/.bashrc` on every stage in `./libs/bash/jenkins/pipelines/vars`
- Respect users shell configuration by carring the pre-exist PATH value through the Aqua modification of the PATH ENV VAR
- slack.slackNotification() argument order in Jenkinsfiles
  
### REMOVE

- printf() regarding checkov warning, no longer valid as we use `git` based IAC module sources

## [0.54.20] - 2024-07-11

### ADD

- disableConcurrentBuilds() to ./libs/bash/pipeline/vars/SharedModules.groovy to prevent parallel executions from stepping on each other

### FIX

- buildDiscarder() expects strings, not integers

## [0.54.19] - 2024-07-11

### FIX

- Correctly write the tfenv version file to the correct location when using TGENV during clean installs

## [0.54.18] - 2024-07-11

### FIX

- Syntax error in libs/jenkins/pipelines/vars/SharedModule.groovy, lists require line ending comma

## [0.54.17] - 2024-07-10

### FIX

- libs/bash/auth/onelogin_bambora_aws.sh now masks MFA token
- libs/bash/auth/onelogin_bambora_aws.sh now exports AWS_PROFILE if invoked using `source` as is documented in the script
- libs/jenkins/pipelines/vars/SharedModule.groovy buildDiscarder var for keeping build artifacts
- libs/jenkins/pipelines/vars/SharedModule.groovy added deleteDir() for successful builds

## [0.54.16] - 2024-07-05

### FIX

- pre-commit diff logic was fixed to compare only the most recent commit

## [0.54.15] - 2024-06-28

### ADD

- deleteDir() to post.success to clean successful workspace to save disk in shared pipeline. 
- options.buildDiscarder() to codify removal of artifacts and builds in lue of web console configuration

## [0.54.14] - 2024-07-03

### FIX

- `libs/bash/git/common.sh` `exec()` only iterating over the first module
- README.md not generated properly causing pipeline and pre-commit hook to fail

## [0.54.13] - 2024-07-01

### FIX

- `git-lfs` is now installed by package installers instead of aqua due to installation issues

## [0.54.12] - 2024-06-21

### ADD

- `./libs/jenkins/pipelines/vars/SharedModule.groovy` Bash invocations now include `-l` to make them login sessions. This triggers a loading of the users `$HOME/.bashrc` more dependably

## [0.54.11] - 2024-06-21

### ADD

- `./libs/bash/iac/batch_git_cycle.sh` to batch process IAC shared modules for when doing library wide changes

## [0.54.10] - 2024-06-20

### REMOVE

- git-lfs checks in Git 2.x hooks due to causing problems using different shebang

## [0.54.9] - 2024-06-20

### FIX

- `libs/jenkins/pipeline/vars/SharedModules.groovy` tagging stage was using incorrect credential type

## [0.54.8] - 2024-06-20

### FIX

- `libs/jenkins/pipeline/vars/SharedModules.groovy` force non-interactive sessions to behave like interactive sessions
- `libs/jenkins/pipeline/vars/SharedModules.groovy` to work with now SCM hosting at Kazan GitLab

## [0.53.8] - 2024-06-19

### FIX

- `libs/bash/git/install.sh` references to `git lfs` changed to `git-lfs` to prevent command splitting

## [0.53.7] - 2024-06-19

### ADD

- `libs/bash/system_tools.sh` to ability to install git 2.x in RHEL 7 based hosts via additional repository from https://packages.endpointdev.com/


## [0.53.6] - 2024-06-06

### FIX

- `./libs/bash/git/install.sh` invocation of `git lfs` are now `git-lfs` to avoid problems interpreting the space between `git` and `lfs` and a command separator

## [0.53.6] - 2024-06-06

### FIX

- `./libs/bash/git/common.sh` generateDiffList() now scoped to only allow paths starting with `terraform/aws/`

## [0.53.5] - 2024-06-03

### FIX

- `xeol` database should update on every run to be more idempotent
- `xeol` does not output junit XML, now uses supported JSON output
- Directory changing when dealing with deployment projects and published module projects

## [0.53.4] - 2024-06-01

### FIX

- `checkov` now does not execute recursivly when running complaince scans

## [0.53.3] - 2024-05-28

### FIX

- Missing new line in some BASH printf
- No longer `exit 1` if `.terraform/modules/modules.json` is not found. Not all deployment modules have upstream modules

## [0.53.2] - 2024-05-28

### FIX

- `libs/bash/git/common.sh` functions `return` instead of `exit 0` on success
- `libs/bash/git/common.sh` iacCompliance() now properly skips checkov on EOL RHEL hosts but not other checks

## [0.53.1] - 2024-05-28

### FIX

- `libs/bash/git/common.sh` generateDiffList() no longer returns exit codes
- `libs/bash/git/hooks/*.sh` return `WARN` and zero exit code if no IAC changes detected

### REMOVE

- IAC init from `./libs/bash/git/common.sh` as this should be done by a person or the pipeline, not a helper

## [0.53.0] - 2024-05-27

### ADD

- WORKSPACE ENV VAR check to git scripts
- Exctracted IAC module diff list creation into `generateDiffList()`

### FIX

- git hook symlink creation
- git hook logic in `common.sh` to be easier to use by automation
- echo replaced with printf

## [0.52.0] - 2024-05-19

### ADD

- TOOLCHAIN_BRANCH parameter to SharedModule.groovy
- libs/bash/common/iac_publish.sh

### FIX

- Reworked SharedModule.groovy to better match execution of pre-commit and pre-push processes

## [0.51.18] - 2024-05-17

### FIX

- Missing execution permission on `libs/bash/common/publish_iac_module_version.sh`

## [0.51.17] - 2024-05-14

### FIX

- Error with extraction of SEM_VER from docs/CHANGELOG.md in downstream projects
- IAC module publishing logic moved into shell script, invoked from pipeline

## [0.51.16] - 2024-05-15

### FIX

- updated `aqua-installer` script version from `v3.0.0` to `v3.0.1` as previous version does not work correctly anymore

## [0.51.15] - 2024-05-14

### FIX

- Do not fail if SemVer is found in CHANGELOG message but already exists in remote

## [0.51.14] - 2024-05-14

### FIX

- Path to `sem_ver_release_tagging` in shared `SharedModule.groovy` in hopes of fixing failing builds
  
## [0.51.13] - 2024-05-13

### FIX

- Disable `checkov` on RHEL 7 hosts due to GLIBC 2.35 not being available

## [0.51.12] - 2024-05-10

### FIX

- xeol tool now fails gracefully due to it's problem with parsing some valid sbom.xml that miss <components><component> tags (for example ops-tooling ecs-service of deployments project)
- xeol "if statement" now properly checks for xeol.yml file instead of trivy.yml

## [0.51.11] - 2024-05-08

### ADD

- IAC compliance scanning tool `checkov` at version 3.2.23 via aqua
- End-of-Life compliance too xeol enabled at version 0.9.15

### FIX

- Incorrect path to `sem_ver_release_tagging.sh` in Jenkinsfile.groovy of the shared pipeline

## [0.51.10] - 2024-05-08

### FIX

- Detect changes to docs/CHANGELOG.md only when looking for SEM_VER to publish. Due to terraform-aws-ecr having a sub-module two CHANGELOG files were being detected
- ./libs/jenkins/pipelines/vars/SharedModule.groovy now triggers SEM_VER publishing and tagging via helper script

## [0.51.9] - 2024-05-06

### FIX

- Pyenv, Opentofu, and Terragrunt version updated
- `./libs/bash/git/install.sh` to handle projects with Git submodules
- Jenkinsfile step to trigger aqua install/update directly

## [0.51.8] - 2024-05-01

### ADD

- `./docs/RUNBOOKS.md` with solution to `ERR: Failed to install Golang via goenv.` when running on Debian/Ubuntu based distributions
- `AWS CLI session-manager-plugin` install on Debian/Ubuntu based distributions

## [0.51.7] - 2024-04-29

### FIX

- Correctly detect KICS version before evaluating if the query library is missing or present

## [0.51.6] - 2024-04-24

### ADD

- KICS now managed by Aqua, no longer by bespoke shell scripts. However, we still need to install the query assets in the users `~/.kics-installer` to enable automation

### FIX

- `git-lfs`, `jq`, and `yq` now managed by Aqua
- Golang moved up to version 1.21
- KICS query library now available via `~/.kics-installer/target_query_libs` symlink to whatever version is installed
- Pyenv installer moved from `./libs/bash/installers/` to `./libs/bash/assets/` to stop messing with [TAB] autocomplete when trying to get to install.sh

## [0.51.5] - 2024-04-23

### FIX

- Change kics download path from .tmp to ~/.kics-installer so it can be reused by downstream projects and it's not wiping itself every time user executes .install.sh.

## [0.51.4] - 2024-04-23

### FIX

- Longstanding bug where if CHANGELOG container two SEM_VER string changes publishing a new tag would fail. Now only pays attention to the first version found during evaluation of SEM_VER string

## [0.51.3] - 2024-04-23

### FIX

- README.md Update/Upgrade instructions based on feedback

## [0.51.2] - 2024-04-23

### FIX

- `./libs/bash/git/common.sh` `documentation()` now adds changed `README.md` to git staged files
- KICS assets copy location during `./libs/bash/install.sh`

## [0.51.1] - 2024-04-23

### FIX

- `./libs/bash/git/common.sh` `generateSBOM` definition and invocation to allow pipelines complete successfully

## [0.51.0] - 2024-04-22

### FIX

- `./libs/bash/aws/pull_and_push_container_images.sh` now used `podman` directly
- `./libs/bash/install.sh` to work with downstream projects
- Clean docs to include upgrade guide
- Downstream example installer `./libs/bash/git/install.sh` no longer copies unused KICS query lib
- Missing `./versions.sh`

### REMOVE

- Bash functions calls as not needed

## [0.50.0] - 2024-04-18

### ADD

- [aqua](https://github.com/aquaproj/aqua) Declarative CLI Version Manager

### FIX

- `Jenkinsfile` to work with the new tool manager

### REMOVED

- Bespoke custom tool version management
- Hashicorp Packer

## [0.41.4] - 2024-04-18

### Fix

- Fix `iam-policy-json-to-terraform` not being installed properly
- Replace $(uname -m) with $ARCH for consistency

## [0.41.3] - 2024-04-18

### Fix

- Returned missing `./libs/bash/installers/pyenv.sh`
- Pipeline stage order; before doing tool grouping re/installs a normal install or update much complete
- Static define path to PIP due to ENV VAR pathing not working as expected

## [0.41.2] - 2024-05-16

### Fix

- `./libs/bash/auth/onelogin_bambora_aws.sh` now validates for all login errors and prints the error message on failure

## [0.41.1] - 2024-05-16

### Fix

- Check IAC module source during pre-push, not always. Enabled local development of modules and committing of in-progress effort

## [0.41.0] - 2024-05-16

### Add

- Version output of tool at the end of the handling function

### Fix

- Only install Golang or Python if missing or `--update true`
- RPM based packages correct reinstall via `-replacepkgs` during `--update true` process
- Tagging logic is now a shared `./libs/bash/common/sem_ver_release_tagging.sh` helper script
- Tagging now only detects changes to the most recent SemVer block in `.docs/CHANGELOG.md`
- When running tool groups and desiring re-install `--update true` must be provided

### Remove

- Deprecated `./libs/bash/system_tools.sh` functions related to language installation

## [0.40.11] - 2024-05-15

### Fix

- `goenv` and `pyenv` shims added to `PATH`

## [0.40.10] - 2024-04-04

### Fix

- Bumped aws-cli version to support aws ecs service connect configuration execution

## [0.40.9] - 2024-03-28

### ADD

- `./libs/bash/aws/pull_and_push_container_images.sh` to help with mass pull-tag-push operations

### FIX

- `./libs/bash/git/common.sh` doNotAllowSharedModulesInsideDeploymentProjects() having incorrect path to IAC `module.json`

## [0.40.8] - 2024-03-25

### FIX

- Architecture detection for ssm-manager-plugin in `cloud_tools.sh`

## [0.40.7] - 2024-03-21

### FIX

- KICS now runs properly on module level instead of ignoring all files

## [0.40.6] - 2024-03-20

### FIX

- Pip is now used on global level to reduce complexity related to local installations with --user parameter
- Fixed wrong usage of $WORKSPACE env that caused file errors in the pipeline
- Fixed checkov not being installed properly

## [0.40.5] - 2024-03-19

### FIX

- Path to junit-* reports reverted to use `$(pwd)`
  
## [0.40.4] - 2024-03-19

### REMOVED

- Returned README validation check to pre 0.40.x disablement

## [0.40.3] - 2024-03-19

### FIX

- Jenkinsfile syntax when running sh sub-shell

## [0.40.2] - 2024-03-19

### FIX

- `WL_GC_TM_WORKSPACE` is now the more specific `WL_GC_TM_WORKSPACE`
- setting `WL_GC_TM_WORKSPACE` now much more easy to understand
  
## [0.40.1] - 2024-03-18

### FIX

- `$(pwd)` and `PRJ_ROOT` replaced with `WORKSPACE`. Must similar solution to lean on a well known ENV VAR
- Missed fn() references terraformCompliance and terraformLint redirected to iacCompliance and iacLint

## [0.40.0] - 2024-03-09

### ADDED

- [pyenv to manage Python and PIP versions](https://github.com/pyenv/pyenv)
- `./libs/bash/install.sh` automatically detects processor architecture (x86, aarch64, etc
- Support for Apple Silicon (Arm/aarch64) based systems

### FIXED

- `#!/bin/bash -e` with `#!/bin/bash` with `set -exo pipefail`
- goenv now installed Golang ONLY if the go binary is not found or `--update true`

### REMOVED

- terrascan due to long open blocking issue and no support for `aarch64`/`arm64` via pre-compiled binaries

## [0.38.4] - 2024-03-14

### FIX

- Support ServiceNow ticket pattern when checking git branch naming

## [0.38.3] - 2024-03-08

### ADDED

- Git branch naming pattern enforcement

## [0.38.2] - 2024-02-21

### FIXED

- Continue processing if a IaC directory shows as deleted in the Git stage

## [0.38.1] - 2024-02-21

### FIXED

- Path to KICS libs

## [0.38.0] - 2024-02-21

### FIXED

- `./libs/bash/ecs_service_port_proxy.sh` iterated to better handle port proxy for remote hosts, not only RDS

## [0.37.1] - 2024-02-15

### FIXED

- Missing URL in failure notification in Jenkinsfile

## [0.37.0] - 2024-02-13

### ADDED

- [containers/skopeo](https://github.com/containers/skopeo) to replace Worldline container-image-mirror bespoke solution in the near future
- Ability to override the toolchain project branch from downstream projects via `./libs/bash/git/install.sh`

### FIXED

- pre-commit and pre-push process to prevent race condition regarding sbom.xml generation and appending to commits

## [0.36.2] - 2024-02-13

### FIXED

- Incorrect Container id extracted from task detail, leading failure of db port forwarding from ecs task

## [0.36.1] - 2024-02-09

### ADDED

- Jenkins triggers.pollSCM to ensure deleted/merged branches are removed from Jenkins daily

## [0.36.0] - 2024-02-01

### FIXED

- Reworked pre-* git hooks to work better with automation tools

## [0.35.2] - 2024-01-31

### FIXED

- Incorrect exit code when no changes to IAC code

## [0.35.1] - 2024-01-31

### FIXED

- Git hooks should have the ability to be executed

## [0.35.0] - 2024-01-29

### ADDED

- pre-push git hook to ensure feature branch compliance before review is created

### FIXED

- pre-commit compliance checks now only diff against the previous commit

## [0.34.3] - 2024-01-29

### Added

- `cat` the contents of an error file when IaC compliance tools fail in `pre_commit_function.sh`

## [0.34.2] - 2024-01-25

### Added

- TLS cipher check helper script

## [0.34.1] - 2024-01-19

### Added

- check for KICS query library during pre-commit execution

### Fixed

- spelling error

## [0.34.0] - 2024-01-18

### Added

- [tofuenv](https://github.com/tofuutils/tofuenv) to manage versions of [OpenTofu](https://opentofu.org/)

## [0.33.1] - 2024-01-17

### Fixed

- syntax error in `libs/bash/aws/ecs_update_service_task.sh`

## [0.33.0] - 2024-01-17

### Fixe

- `libs/bash/aws/ecs_update_service_task.sh` to ignore activegate and hazelcast named services

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

- checkov now only scans the directly it is initialized in, no more sub-directory recursive scanning

## [0.32.20] - 2023-12-11

### Fixed

- xeol should not yet bet enabled

## [0.32.19] - 2023-12-11

### Fixed

- comment that should not be un-characterized

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

- the ability to select the container within an ECS task using ./libs/bash/aws/ecs_task_shell_connection.sh

## [0.32.14] - 2023-11-20

### Fixed

- missing process to install tfsec
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

- increase pipeline timeout from 15 mins to 30 mins to account for when Python needs to be compiled

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

- Fixed installation of trivy package by putting current path prefix
- Removed unwanted packages(ca-certification, gnupg2, wget) installation from apt-systems
- Added gnupg2 package installation for Fedora and Red Hat

## [0.23.0] - 2023-08-28

### Added

- Added script to install trivy
- Added script to install podman and builah for debian

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

- xeol system tool

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
