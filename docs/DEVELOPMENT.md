# Development

## Successful Run Example

Given all tools are installed the follow takes approximately 5 seconds.

```sh
bash-5.2$ ./libs/bash/install.sh 
INFO: Executing with the following argument configurations.
ALTARCH: x86_64
ARCH: amd64
BIN_DIR: /usr/local/bin
ORIG_PWD: /home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management
PLATFORM: linux
WL_GC_TM_WORKSPACE: /home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management
SHELL_PROFILE: /home/david/.worldline_pps_profile
SKIP_AWS_TOOLS: 
SKIP_MISC_TOOLS: 
SKIP_SYSTEM_TOOLS: 
SKIP_IAC_TOOLS: 
UPDATE: false
INFO: Changing to project root.
INFO: Sourcing tool versions.sh in install.sh.
INFO: Output tool target versions.
GOENV_VER: 2.1.4
GO_VER: 1.18.2
PYTHON_VER: 3.8.18
PYTHON_MINOR_VER: 3.8
XEOL_VER: 0.6.0
AWSCLI_VER: 2.13.8
IPJTT_VER: 1.8.2
ONELOGIN_AWS_CLI_VER: 0.1.19
PKR_VER: 1.9.2
TOFU_VER: 1.6.0
TF_VER: 1.6.2
TFENV_VER: 3.0.0
TG_VER: 0.48.7
TGENV_VER: 1.1.0
TOFUENV_VER: 1.0.3
INFRACOST_VER: 0.10.28
KICS_VER: 1.7.5
TFDOCS_VER: 0.16.0
TFLINT_VER: 0.47.0
TFSEC_VER: 1.28.4
TRIVY_VER: 0.44.1
TRSCAN_VER: 1.18.3
INFO: PATH value is: /home/david/.local/bin:/home/david/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management/libs/bash:/home/david/.goenv/bin:/home/david/.goenv/shims:/home/david/.local/bin:/home/david/.tfenv/bin:/home/david/.tgenv/bin:/home/david/.tofuenv/bin
INFO: Installing system tool from source.
which: no apt in (/home/david/.local/bin:/home/david/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management/libs/bash:/home/david/.goenv/bin:/home/david/.goenv/shims:/home/david/.local/bin:/home/david/.tfenv/bin:/home/david/.tgenv/bin:/home/david/.tofuenv/bin)
INFO: Updating and installing system tools via yum.
Last metadata expiration check: 1:47:35 ago on Fri 12 Jan 2024 09:35:28 AM CET.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1:47:37 ago on Fri 12 Jan 2024 09:35:28 AM CET.
Package bzip2-1.0.8-13.fc38.x86_64 is already installed.
Package bzip2-devel-1.0.8-13.fc38.x86_64 is already installed.
Package ca-certificates-2023.2.60_v7.0.306-1.0.fc38.noarch is already installed.
Package curl-8.0.1-6.fc38.x86_64 is already installed.
Package gcc-13.2.1-4.fc38.x86_64 is already installed.
Package gcc-c++-13.2.1-4.fc38.x86_64 is already installed.
Package git-2.43.0-1.fc38.x86_64 is already installed.
Package git-lfs-3.4.1-1.fc38.x86_64 is already installed.
Package gnupg2-2.4.0-3.fc38.x86_64 is already installed.
Package gnupg2-2.4.0-3.fc38.x86_64 is already installed.
Package jq-1.6-16.fc38.x86_64 is already installed.
Package libffi-devel-3.4.4-2.fc38.x86_64 is already installed.
Package parallel-20230822-1.fc38.noarch is already installed.
Package podman-5:4.8.2-1.fc38.x86_64 is already installed.
Package python3-distutils-extra-2.39-25.fc38.noarch is already installed.
Package tree-2.1.0-2.fc38.x86_64 is already installed.
Package unzip-6.0-60.fc38.x86_64 is already installed.
Package dnf-utils-4.4.4-1.fc38.noarch is already installed.
Package zlib-devel-1.2.13-3.fc38.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
"*.iso" already supported
"*.zip" already supported
"*.gz" already supported
INFO: Updating Go via goenv.
HEAD is now at bce57ab Update APP_VERSION to 2.1.9 (#353)
Previous HEAD position was bce57ab Update APP_VERSION to 2.1.9 (#353)
HEAD is now at 183eef5 chore: update changelog and release process (#340)
INFO: Processing Python system tools.
INFO: Processing pip system tools.
1.18.2 (set by /home/david/.goenv/version)
go version go1.18.2 linux/amd64
pip 23.3.1 from /home/david/.local/lib/python3.8/site-packages/pip (python 3.8)
Python 3.8.18
INFO: Processing AWS tools.
INFO: Output AWS tool versions.
iam-policy-json-to-terraform 1.8.2
onelogin-aws-cli Name: onelogin-aws-cli
Version: 0.1.19
Summary: Onelogin assume AWS role through CLI
Home-page: https://github.com/physera/onelogin-aws-cli
Author: Cameron Marlow
Author-email: cameron@physera.com
License: MIT License
Location: /home/david/.local/lib/python3.8/site-packages
Requires: boto3, keyring, onelogin, requests
Required-by: 
aws-cli/2.13.8 Python/3.11.4 Linux/6.6.9-100.fc38.x86_64 exe/x86_64.fedora.38 prompt/off
INFO: Processing MISC tools.
WARN: Not installing Hashicorp Packer on RHEL basd systems due to package name collision
INFO: Processing TERRAFORM tools.
Switching default version to v1.6.2
Default version (when not overridden by .terraform-version or TFENV_TERRAFORM_VERSION) is now: 1.6.2
[INFO] Switching to v0.48.7
[INFO] Switching completed
Switching default version to v1.6.0
Default version (when not overridden by .opentofu-version or TOFUENV_TOFU_VERSION) is now: 1.6.0
INFO: Output Terraform tool versions.
checkov 2.3.361
Version: 0.44.1
Vulnerability DB:
  Version: 2
  UpdatedAt: 2023-11-14 12:12:55.648130557 +0000 UTC
  NextUpdate: 2023-11-14 18:12:55.648130307 +0000 UTC
  DownloadedAt: 2023-11-14 14:29:45.971413325 +0000 UTC
terrascan version: v1.18.3
Infracost v0.10.28

Update: A new version of Infracost is available: v0.10.28 → v0.10.31
  $ curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
Terraform v1.6.2
on linux_amd64
terragrunt version v0.48.7
tfenv 3.0.0-18-g1ccfddb
tgenv 1.1.0
OpenTofu v1.6.0
on linux_amd64
Keeping Infrastructure as Code Secure development
INFO: Sourcing /home/david/.worldline_pps_profile
INFO: Changing back to original working dir.
INFO: Please start your shell session to ensure the PATH value is reloaded.
INFO: Toolchain install.sh completed successfully.
```

Force re-installing tools depends on theset of tools being reinstalled. But here is the system tools being force reinstalled.

```sh
bash-5.2$ ./libs/bash/install.sh --skip_aws_tools true --skip_misc_tools true --skip_iac_tools true --update true
INFO: Executing with the following argument configurations.
ALTARCH: x86_64
ARCH: amd64
BIN_DIR: /usr/local/bin
ORIG_PWD: /home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management
PLATFORM: linux
WL_GC_TM_WORKSPACE: /home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management
SHELL_PROFILE: /home/david/.worldline_pps_profile
SKIP_AWS_TOOLS: true
SKIP_MISC_TOOLS: true
SKIP_SYSTEM_TOOLS: 
SKIP_IAC_TOOLS: true
UPDATE: true
INFO: Changing to project root.
INFO: Sourcing tool versions.sh in install.sh.
INFO: Output tool target versions.
GOENV_VER: 2.1.4
GO_VER: 1.18.2
PYTHON_VER: 3.8.18
PYTHON_MINOR_VER: 3.8
XEOL_VER: 0.6.0
AWSCLI_VER: 2.13.8
IPJTT_VER: 1.8.2
ONELOGIN_AWS_CLI_VER: 0.1.19
PKR_VER: 1.9.2
TOFU_VER: 1.6.0
TF_VER: 1.6.2
TFENV_VER: 3.0.0
TG_VER: 0.48.7
TGENV_VER: 1.1.0
TOFUENV_VER: 1.0.3
INFRACOST_VER: 0.10.28
KICS_VER: 1.7.5
TFDOCS_VER: 0.16.0
TFLINT_VER: 0.47.0
TFSEC_VER: 1.28.4
TRIVY_VER: 0.44.1
TRSCAN_VER: 1.18.3
INFO: PATH value is: /home/david/.local/bin:/home/david/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management/libs/bash:/home/david/.goenv/bin:/home/david/.goenv/shims:/home/david/.local/bin:/home/david/.tfenv/bin:/home/david/.tgenv/bin:/home/david/.tofuenv/bin
INFO: Installing system tool from source.
which: no apt in (/home/david/.local/bin:/home/david/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management/libs/bash:/home/david/.goenv/bin:/home/david/.goenv/shims:/home/david/.local/bin:/home/david/.tfenv/bin:/home/david/.tgenv/bin:/home/david/.tofuenv/bin)
INFO: Updating and installing system tools via yum.
Last metadata expiration check: 1:52:13 ago on Fri 12 Jan 2024 09:35:28 AM CET.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1:52:15 ago on Fri 12 Jan 2024 09:35:28 AM CET.
Package bzip2-1.0.8-13.fc38.x86_64 is already installed.
Package bzip2-devel-1.0.8-13.fc38.x86_64 is already installed.
Package ca-certificates-2023.2.60_v7.0.306-1.0.fc38.noarch is already installed.
Package curl-8.0.1-6.fc38.x86_64 is already installed.
Package gcc-13.2.1-4.fc38.x86_64 is already installed.
Package gcc-c++-13.2.1-4.fc38.x86_64 is already installed.
Package git-2.43.0-1.fc38.x86_64 is already installed.
Package git-lfs-3.4.1-1.fc38.x86_64 is already installed.
Package gnupg2-2.4.0-3.fc38.x86_64 is already installed.
Package gnupg2-2.4.0-3.fc38.x86_64 is already installed.
Package jq-1.6-16.fc38.x86_64 is already installed.
Package libffi-devel-3.4.4-2.fc38.x86_64 is already installed.
Package parallel-20230822-1.fc38.noarch is already installed.
Package podman-5:4.8.2-1.fc38.x86_64 is already installed.
Package python3-distutils-extra-2.39-25.fc38.noarch is already installed.
Package tree-2.1.0-2.fc38.x86_64 is already installed.
Package unzip-6.0-60.fc38.x86_64 is already installed.
Package dnf-utils-4.4.4-1.fc38.noarch is already installed.
Package zlib-devel-1.2.13-3.fc38.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
"*.iso" already supported
"*.zip" already supported
"*.gz" already supported
INFO: Installing xeol.
[info]\033[0m checking github for release tag='v0.6.0' \033[0m
[info]\033[0m fetching release script for tag='v0.6.0' \033[0m
[info]\033[0m checking github for release tag='v0.6.0' \033[0m
[info]\033[0m using release tag='v0.6.0' version='0.6.0' os='linux' arch='amd64' \033[0m
[info]\033[0m installed /usr/local/bin/xeol \033[0m
INFO: Installing goenv to /home/david/.goenv to enable Go
...
Installing collected packages: wheel, pip
Successfully installed pip-23.3.2 wheel-0.42.0

[notice] A new release of pip is available: 23.0.1 -> 23.3.2
[notice] To update, run: python3 -m pip install --upgrade pip
INFO: Update pip via itself.
Defaulting to user installation because normal site-packages is not writeable
Collecting pip
  Using cached pip-23.3.2-py3-none-any.whl.metadata (3.5 kB)
Using cached pip-23.3.2-py3-none-any.whl (2.1 MB)
Installing collected packages: pip
  Attempting uninstall: pip
    Found existing installation: pip 23.3.2
    Uninstalling pip-23.3.2:
      Successfully uninstalled pip-23.3.2
Successfully installed pip-23.3.2
Defaulting to user installation because normal site-packages is not writeable
Collecting Cmake
  Downloading cmake-3.28.1-py2.py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl.metadata (6.3 kB)
Downloading cmake-3.28.1-py2.py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl (26.3 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 26.3/26.3 MB 12.4 MB/s eta 0:00:00
Installing collected packages: Cmake
Successfully installed Cmake-3.28.1
1.18.2 (set by /home/david/.goenv/version)
go version go1.18.2 linux/amd64
pip 23.3.2 from /home/david/.local/lib/python3.8/site-packages/pip (python 3.8)
Python 3.8.18
INFO: Sourcing /home/david/.worldline_pps_profile
INFO: Changing back to original working dir.
INFO: Please start your shell session to ensure the PATH value is reloaded.
INFO: Toolchain install.sh completed successfully.
```
