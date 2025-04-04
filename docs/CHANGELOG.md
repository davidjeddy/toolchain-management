# CHANGELOG

## References

- [keep a changelog](https://keepachangelog.com/en/1.0.0/)

[[ACTION]] [[Service]] [[Description]]

Action Keywords:

- `ADD`   : Functionality did not exist previously.
- `FIX`   : Functionality existed but did not behave as expected.
- `REMOVE` : Functionality is no longer available.

## [0.66.10] - 2025-03-27

### FIX

- docker to podman alias should be created in the users $HOME/.toolchainrc

## [0.66.9] - 2025-03-27

### FIX

- the podman alias should be in the projects .toolchainrc, not changing the users profile .bashrc

## [0.66.8] - 2025-03-26

### FIX

- another attempt at ensuring the docker alias is injected only once

## [0.66.7] - 2025-03-26

### FIX

- asdf-vm back to 0.15.x release family due to problem with egress network connection handling when using Golang programs
  - https://github.com/asdf-vm/asdf/issues/2043 and https://github.com/aquaproj/aqua/issues/3152
- asdf-vm version checking logic for updating, comparisons where backwards
- alias creation for docker in user bashrc

## [0.66.6] - 2025-03-25

### FIX

- append_path to shims not properly evaluating asdf shim path during install
- do not track log outputs

## [0.66.5] - 2025-03-26

### FIX

- possible for docker alias to podman now a user alias instead of an alias in /usr/bin; which was getting cleared on re-run of dnf/yum

## [0.66.4] - 2025-03-25

### FIX

- tflint update needs removal of CLI arg `--no-module`

## [0.66.3] - 2025-03-25

### FIX

- copy asdf .tool-versions both before and after plugins are added, just to be sure
- kics regression; cannot use `v2.1.6` without golang `1.23`; which inturn is not yet available on Fedora 40

## [0.66.2] - 2025-03-24

### FIX

- asdf binary architecture detection now defaults to `amd64`
- asdf install regression corrected; we DO need to parse .tool-version explicitly

## [0.66.1] - 2025-03-24

### FIX

- asdf now starts with an empty `.tool-versions in $HOME
- asdf install and plugin process now work with sonarscanner in .tool-versions

## [0.66.0] - 2025-03-21

### FIX

- `asdf-vm` upgraded to `0.16.x` release family
- Correctly remove terraform-compliance build dir when updating
- Version updated any tool that has a newer release tag

### REMOVE

- Unused .*version files

## [0.65.01] - 2025-03-17

### ADD

- syft to automatically generate sbom.xml during pre-push Git Hook for all downstream projects

## [0.65.0] - 2025-03-17

### REMOVE

- Logic to skip some tools when hosted on a Red Hat

## [0.64.19] -2025-03-11

### FIX

- dnf reinstall of `python-pip` automatically, now include assumeyes
 
## [0.64.18] - 2025-03-10

### FIX

- dnf reinstall of `python-pip` is needed else `pip` is not found on the $PATH

### REMOVE

- dnf install of `python-pip` does not accept a version constraint, always use latest

## [0.64.17] - 2025-03-10

### FIX

- `pip` install package is `python-pip` not the expected `python3-pip` like other Python3 packages

## [0.64.16] - 2025-03-06

### FIX

- Add instance name to EC2 output to make it easier to know what instance is being connected to

## [0.64.15] - 2025-03-03

### FIX

- `sonar-scanner` updated from `4.2.0.1873` to `7.0.1.4817`
- error thrown by asdf if 3rd party plugins are not present in $HOME/.tool-versions
- Python3 pip installation now via `dnf` for reliability

## [0.64.14] - 2025-02-28

### FIX

- pip install process, now uses OS package manager

## [0.64.13] - 2025-02-27

### FIX

- Golang version now pinned using the same pattern as Python
- Python invocation in asdf_tools.sh before `asdf install`

## [0.64.12] - 2025-02-25

### FIX

- Python bumped from `3.12.8` to `3.12.9`
 
## [0.64.11] - 2025-02-25

### FIX

- ContainerImage now uses the :warning: emoji in place of :pipeline-failed: for the Slack message when an image fails to build

## [0.64.10] - 2025-02-21

### FIX

- We are not ready to goto asdf-vm 0.16.x; reset back to 0.15.x

## [0.64.9] - 2025-02-21

### ADD

- The ability to select the Git hook collection to be used with a project based on user selection during `./libs/bash/install.sh` execution

## [0.64.8] - 2025-02-20

### FIX

- fixed `append_add_path` to append path to PATH env as well
- fixed `tfenv`, `tofuenv` and `tgenv` version initialization

## [0.64.7] - 2025-02-20

### FIX

- `asdf-checkov: dependencies aren't met and the installation won't proceed` error during fresh installs
- Moved `append_libs_to_sys_path.sh` to inside `./libs/bash/`

## [0.64.6] - 2025-02-18

### FIX

- Install Python if installing asdf_tools.sh as checkov requires Python 3.x

## [0.64.5] - 2025-02-14

### FIX

- README.md now documents a usage override examples
- So not output `asdf` packages if `asdf` is not installed

## [0.64.4] - 2025-02-14

### FIX

- Missing fn() start outputs
- Put container tools behind a feature flag to better work with down stream container project
- SonarScanner now installed via asdf-vm, no more ad-hoc Bash script

## [0.64.3] - 2025-02-14

### FIX

- Updated os package list with commonly used tools from wl-gc-* projects
- Better explained to not repeat packages in downstream projects that are managed by this project

## [0.64.2] - 2025-02-12

### FIX

- infracost from asdf-vm due to 401 response from Github for the plugin project

## [0.64.1] - 2025-02-12

### REMOVE

- infracost from asdf-vm due to 401 response from Github for the plugin project

## [0.64.0] - 2025-02-12

### FIX

- `./libs/bash/iac_tools.sh` blocks sorted alphabetically
- `./libs/bash/reset.sh` is self executing so needs bash shebang
- `./.gitlab/CODEOWNERS` to use groups rather than specific users

### REMOVE

- Python and Python tools as no longer needed
- `./bash/auth` as both OneLogin and direct AWS authentication is either no longer support

## [0.63.18] - 2025-02-04

### ADD

- [syft](https://github.com/anchore/syft) to generate SBOM via asdf-vm

### FIX

- AWS ENV VAR unset helper errant characters

## [0.63.17] - 2025-02-03

### FIX

- `./docs/CHANGELOG` action header indications
- docs in header of `./libs/bash/aws/iam_assume_role.sh`
- syntax of `./libs/bash/aws/iam_assume_role.sh` to better align with existing helpers

## [0.63.16] - 2025-02-03

### ADD

- `./libs/bash/aws-unset_env_var.sh` to remove set AWS_* ENV VARs, useful when switching accounts in using `aws-sso` and the same terminal session
- optional `./libs/bash/append_libs_to_sys_path.sh` helper that will append lib paths to system,s ENV VAR PATH

### FIX

- `./libs/jenkins/pipelines/vars/ContainerImage.groovy` now uses `podman ...--squash` argument when building container images to reduce image sizes

## [0.63.15] - 2025-01-28

### REMOVE

- `terraform-compliance` until more testing and integration can be completed to ensure stability of pipelines

## [0.63.14] - 2025-01-27

### FIX

- opentofu from `1.8.0` to `1.9.0`

## REMOVE

- `./docs/TESTING.md` as provided no value

## [0.63.13] - 2025-01-27

### FIX

- Ensure usage of `./libs/bash/aws/iam_assume_role.sh` is triggered via `source` not execution to ensure role assumption

## [0.63.12] - 2025-01-24

### FIX

- Set `GOPROXY='https://proxy.golang.org,direct'` before KICS build to temporary workaround issue with incorrect SSL on https://go.opencensus.io/ during dependencies download that was causing build to silently fail

## [0.63.11] - 2025-01-22

### FIX

- Removed `AWS_PROFILE` checks from `./libs/bash/aws/*.sh` helper scripts as `aws-sso-profile` does not set it, preventing the scripts from being used

## [0.63.10] - 2025-01-17

### ADD

- `./libs/bash/aws/iam_assume_role.sh` helper script for authorization after authentication via `aws-sso`

## [0.63.9] - 2025-01-16

### ADD

- `bash-completion` dependency to enable `aws-sso` profile completion

## [0.63.8] - 2025-01-14

### ADD

- `pinentry` dependency for `gpg` to configure `aws-sso`

## [0.63.7] - 2025-01-09

### FIX

- IAC module version check getting project id
- moduleVersionCheck() disabled until we can refactor the loop and prevent the url encoding from smashing all the remote addresses together

## [0.63.6] - 2025-01-09

### FIX

- `terraform-compliance` check will run `init` if cache directory does not exist as is needed in automation

## [0.63.5] - 2025-01-08

### FIX

- check for error response from GitLab when authenticating using `$HOME/.terraformrc` credentials
- create module `plan.out` only if it does not already exist when running `terraform-compliance` tool
- do not init  modules for `terraform-compliance` tool, author should init modules before committing changes

## [0.63.4] - 2025-01-08

### ADD

- `aws-sso-cli` asdf plugin to enable authentication via AWS IAM Identity Center method
- `pass` credential manager for use with `aws-sso`

### FIX

- asdf-vm upgraded to version `0.15.0`

## [0.63.3] - 2024-12-19

### FIX

- pre-commit check for module version longer longer errantly exits when evaluating IAC provider modules

## [0.63.2] - 2024-12-19

### ADD

- IAC module version check in `./libs/bash/git/common.sh` called `moduleVersionCheck()` that is triggered during pre-commit
  - if changed files define a shared module and that module is not at the latest published version, exit with error

## [0.63.1] - 2024-12-16

### REMOVE

- `*dnf` packages from PIP requirements.txt, OS package manager version should not be managed by user-space processes

## [0.63.0] - 2024-12-16

### ADD

- `./libs/jenkins/pipelines/vars/ContainerImage.groovy` shared pipeline to centralize container image building for images hosted in ECR.
  - Does NOT and will not support any registry other than AWS ECR
  - Includes `dive` quality check utility
  - Integration with GitLab and daily cron build checking (just like IAC modules)

## [0.62.3] - 2024-12-12

### FIX

- Only run `terraform-compliance` on deployment modules

## [0.62.2] - 2024-12-09

### FIX

- `./libs/bash/reset.sh` updated to 0.62.x paths
- `asdf-vm` install now removed plugins before installing

### REMOVE

- `infracost` due to not being used and 401 return from GitHub during install

## [0.62.1] - 2024-12-09

### FIX

- terraform-compliance output logging and init if needed

## [0.62.0] - 2024-12-09

### FIX

- `./libs/jenkins/pipeline/vars/SharedModule.groovy` to use var for target branch instead of 'main' repeating
- Renamed `exec()` is a special builtin function in Bash 5
- `generateDiffList()` when the output is an empty string (no IAC changes detected)

## [0.61.21] - 2024-12-05

### ADD

- `xz` is now installed via `dnf` to ensure the system has it available

### FIX

- Disable `checkov` on Red Hat 7 hosts due to Python incompatibility
- Disable `terraform-compliance` on Red Hat 7 hosts due to Python incompatibility

## [0.61.20] - 2024-12-05

### FIX

- Again with `terraform-compliance` install process

## [0.61.19] - 2024-12-05

### FIX

- `terraform-compliance` output now plan.json to align with community pattern

## [0.61.18] - 2024-12-04

### ADD

- `terraform-compliance` installed via PIP, not container image, to support execution in container based Jenkins nodes

## [0.61.17] - 2024-12-04

### ADD

- `terraform-compliance` IAC tool as the policy-as-code solution

## [0.61.16] - 2024-12-03

### FIX

- Spelling and helper script section formatting

## [0.61.15] - 2024-11-28

### FIX

- `./libs/jenkins/pipeline/vars/SharedModule.groovy` node selection labels updated to better land on the IAC specific Jenkins nodes

## [0.61.14] - 2024-11-27

### FIX

- `./libs/jenkins/pipeline/vars/SharedModule.groovy` post.failure and post.fix curl calls to Slack updated to new syntax

## [0.61.13] - 2024-11-21

### FIX

- Path to tagging script in `Jenkinsfile`

## [0.61.12] - 2024-11-21

### ADD

- Python package `chardet==5.2.0` to prevent some warning outputs

## [0.61.11] - 2024-11-18

### ADD

- Missing, but very much needed, `awscli` in `system_tools.sh`

### FIX

- `Jenkinsfile` to tag project when changes in `./docs/CHANGELOG.md` are detected
- Missing `--assumeyes` argument on dnf when installing `session-manager-plugin`

## [0.61.10] - 2024-11-12

### FIX

- `./libs/bash/jenkins/SharedModule.groovy` usage of TOOLCHAIN_BRANCH, should be params.TOOLCHAIN_BRANCH
- `dnf .. -y` to `dnf .. --assumeyes` to be more explicit
- Added logic to `./libs/bash/iac/compliance_and_security_scanning.sh` to scan against main branch when in a pipeline. this will ensure all changes in a feature branch are scanned, not only the changes in the most recent commit.
- Allow middle dash character (-) in branch names

## [0.61.9] - 2024-11-08

### FIX

- Fix logic of `delete_line` to delete only if line matched

## [0.61.8] - 2024-11-08

### FIX

- Do not exit non-zero from utils `delete_line()` if the old line is not found

## [0.61.7] - 2024-11-08

### FIX

- Use `WL_GC_TM_WORKSPACE` when sourcing common/utils.sh else will get `file not found` when building images

## [0.61.6] - 2024-11-08

### FIX

- `append_add_path` was revamped to avoid generating code which may change exit status

## [0.61.5] - 2024-11-06

### ADD

- `requirements_localstack_runtime.txt` to version pin for `localstack[runtime]` install process

### FIX

- Allow upper case A-Z in branch names via `validateBranchName()`
- Check for QEMU host to prevent sonar-scanner install as needed
- ENV VAR `GOROOT` value when building kics binary
- Functions calls now occur in `./lib/bash/install.sh` for tool groups as the sourced files are no longer executable resources
- Separated iac_tools into smaller logic blocks to allow a single tool to fail, not the entire group

### REMOVE

- `install_kics_query_library()` as no longer needed
- Symlink of KICS query library, now uses from `$HOME/.kics/assets/queries/*`

## [0.61.4] - 2024-11-04

### FIX

- Decouple toolchain rc file from .bashrc
- Prevent re-adding same path to the PATH environment variable
- Make sourced scripts non-executable

## [0.61.3] - 2024-10-30

### FIX

- Incorrect path to `compliance_and_security_scanning.sh` in `./libs/jenkins/pipelines/vars/SharedModule.groovy`

## [0.61.2] - 2024-10-30

### FIX

- Permissions when reconfiguring Podman

### REMOVE

- Unused `./libs/bash/golang.sh`
- Unused `./libs/bash/pip.sh`

## [0.61.1] - 2024-10-30

### FIX

- `$HOME_USER_BIN` should not be escaped when used in the path for sonar-scanner

### REMOVE

- Regarding ENV VAR `TF_PLUGIN_CACHE_DIR` we do not put trailing slashes in paths

## [0.61.0] - 2024-10-25

### ADD

- `asdf` as the user space package manager
- `jenkins_user_patches` as a place to hold CI/CD/CR user specific configurations
- Podman configuration now includes enables lingering sessions and registry configuration

### FIX

- `./libs/bash/git/install.sh` informational outputs updated to reflect effort to decouple TC from downstream install processes
- `Jenkinsfile` now has a `shellPreamble` to abstract commonly used setup commands
- AWS Session Manager plugin now installed via `curl` and `dnf`, no more `rpm` dependency
- IaC related helper scripts to `./libs/iac/*.sh`

### REMOVE

- `./libs/bash/python.sh` as no longer used, Python3 installed via `dnf`
- `apt` system package management from `system_tools.sh` as no longer supported
- `aqua` as the user space package manager due to incompatibility with egress Network firewall and TLS session management
- `pip3` to `pip` symlinking as no longer supported, use `pip3` directly
- `python3` to `python` symlinking as no longer supported, use `python3` directly
- `yum` system package management from `system_tools.sh` as no longer supported
- Dependency on the `jenkins-pipeline-lib` as the slack notification no longer works as expected; using raw `curl` instead
- RedHat Linux 7* support as no longer supported

## [0.60.0] - 2024-10-17

## FIX

- Restore the project to the last stable version (0.59.3) of revision number: 3eab9686b34704ca44cf6b6eeed9249a24bca3d6 
- This restores all the files other than CHANGELOG.md, git history is not rewritten for this purpose

## [0.59.4] - 2024-10-14

## ADD

- Wrapped IaC KICS library in a function call
- `keyring` PIP package

## FIX

- pip binary location is not explicitly set to `$HOME/.local`; similar to maven and sonar-scanner
- `pip uninstall` now executed before install to ensure packages go into the correct location
- Reference to Oracle VirtualBox to Windows WSL due to licensing issues with Oracle
- Replaced `~/` with `$HOME` to better align with best practices
- Aqua processes now better isolated between install of the tool and  install of the packages

## REMOVE

- `-f ${SESSION_SHELL} &&` from *env install logic as repetitive

## [0.59.3] - 2024-10-14

### FIX

- `./libs/bash/git/install.sh` error `./versions.sh not found` error

## [0.59.2] - 2024-10-10

### FIX

- Create dir path `$HOME_BIN_DIR` if not exists
- Replace static `$HOME/.local/bin` with `$HOME_BIN_DIR`

## [0.58.1] - 2024-10-10

### FIX

- Better handle situation where the end-user has multiple entries in `~/.terraformrc`

## [0.59.0] - 2024-10-07

### FIX

- AWS Session Manager plugin moved to `system_tools.sh`
- Extracted `pip` logic to its own script
- Extracted Java tooling install logic to its own script
- Renamed `process_goenv()` to `install_golang_via_goenv`
- Renamed `process_pyenv()` to `install_python_via_pyenv`
- Split Golang, IaC, Java, and Python tools into separate installers to assist in building container based images

### REMOVE

- `additional_tools.sh` as no longer needed
- The requirement of `sudo` permissions outside of `system_tools.sh` to better support containerized hosts

## [0.58.3] - 2024-10-03

### FIX

- `cat /eta/*release` should be `/etc/*release` when checking OS

## [0.58.2] - 2024-10-02

### FIX

- REVERT changes to `./libs/bash/install.sh`. Only `./libs/bash/git/install.sh` should have been changed in the last release
- REVERT changes to `./libs/jenkins/SharedModule.groovy`, still want to clone the Toolchain into .tmp during pipeline execution

## [0.58.1] - 2024-10-01

### ADD

- ADD logic to skip tooling install if executed on a CI pipeline host

### FIX

- Jenkinsfile can now uninstall all tools via `./libs/bash/reset.sh` on non-GI_* hosts
- Jenkinsfile syntax clean up for both this project and SharedModules.groovy
- Installer updated to version 0.8.2
  - No longer triggers tool install when Toolchain is installed on automation hosts

### REMOVED

- README section dealing with reset of hosts using <= 0.50.0 of the Toolchain

## [0.58.0] - 2024-09-30

### FIX

- Project pipeline now runs daily on EC2 based Jenkins agents to manage tool versions. Downstream projects no longe are required to do tool checks
  - Note: This only applies to EC2 hosts. ECS hosts continue to get a new image build to make changes

## [0.57.5] - 2024-09-26

### ADD

- Compiler packages `system_tools.sh`

### FIX

- Installer helpers now all use "source $SESSION_SHELL"
- `./libs/bash/aws/ec2_ssm_start_session.sh` now accepts $1 and $2 CLI arguments
  
## [0.57.4] - 2024-09-17

### FIX

- `bridgecrewio/checkov` set to version that still satisfies pathing pattern pre removal of the version from the release artifact
- `goenv` changes namespace in GitHub
- Jenkinsfile no longer configures `set -x` on BASH shell invocations

## [0.57.3] - 2024-09-13

### ADD

- `./libs/bash/aws/ec2_ssm_start_session.sh` to make connecting to EC2 instances via SSM a little easier

## [0.57.2] - 2024-09-10

### FIX

- `./libs/bash/reset.sh` editing the wrong BASH profile files
- `./libs/bash/reset.sh` only runs as with `sudo` or `root` permissions
- `./libs/bash/reset.sh` updated to remove more tooling controls inside user `$HOME`
- `curl` invocation argument `--verbose` with `--show-error`
- `sonar-scanner --version` no longer outputs on QEMU hosts due to error
- Stop reinstalling the AWS CLI `session-manager-plugin` on every execution

## [0.57.2] - 2024-10-07

### FIX

- Missing package management for `dmidecode`
- ShellCheck warnings in `./libs/bash/*.sh`

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
- ability to skip additional, aqua, iac, language, and system tools using ENV VAR
- if `SESSION_SHELL` file does not exist, we now create it
- Missing `setuptools` Python package
- noted when `apt` (Debian/Ubuntu) and `yum` (RHEL) support will be removed from system tools
- sonar-scanner CLI to `additional_tools.sh`
- SonarQube `sonar-scanner` to additional tools
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

- `apk` evaluations, no longer using Alpine. Lets stick w/ Fedora for consistency

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
- pyenv failing to install properly due to ~/.bashrc not being interpreted correctly
- Stop putting the start/end indicators into ~/.bashrc repeatably
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

- `./libs/bash/git/hooks/pre-*` by moving the functions to common.sh; now the pre-* hook scripts are once again nearly identical

## [0.54.32] - 2024-07-25

### FIX

- Method calls on objects not allowed outside "script" blocks.

## [0.54.31] - 2024-07-24

### FIX

- Working on CODEOWNERS feature enablement

## [0.54.30] - 2024-07-24

### FIX

- `libs/bash/git/install.sh` no longer updates itself causing errors in the process 

## [0.54.29] - 2024-07-24

### FIX

- libs/jenkins/pipeline/vars/SharedModule.groovy logRotator now uses Groovy List for configuration
- Working on CODEOWNERS feature enablement

## [0.54.28] - 2024-07-24

### FIX

- Working on CODEOWNERS feature enablement

## [0.54.27] - 2024-07-24

### FIX

- Working on CODEOWNERS feature enablement

## [0.54.26] - 2024-07-24

### FIX

- Working on CODEOWNERS feature enablement

## [0.54.25] - 2024-07-24

### FIX

- Working on CODEOWNERS feature enablement

## [0.54.25] - 2024-07-24

### ADD

- ./CODEOWNERS to scope who can approve merge requests
- ./libs/bash/aws/backup_delete_all_recovery_points.sh to remove recovery points from AWS Backup Plan

## [0.54.24] - 2024-07-19

### FIX

- Removed `grep "terraform/aws/"` from filtering out `generateDiffList()` output - it caused shared modules projects to skip most of the pre-commit logic

## [0.54.23] - 2024-07-18

### FIX

- `./libs/bash/git/hooks/pre-commit` autoUpdate() was not properly getting tags for toolchain project

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
- Respect users shell configuration by carrying the pre-exist PATH value through the Aqua modification of the PATH ENV VAR
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

- `checkov` now does not execute recursively when running compliance scans

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
- Extracted IAC module diff list creation into `generateDiffList()`

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

- Missing execution permission on `libs/bash/iac/publish_iac_module_version.sh`

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
- KICS query library now available via `~/.kics/assets/queries` symlink to whatever version is installed
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
