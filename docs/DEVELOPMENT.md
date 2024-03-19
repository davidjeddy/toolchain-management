# Development

## Process

- Clone and install an upstream project
- In the upstream, comment `./libs/bash/install.sh` to not remove .tmp nor `git clone ...` the toolchain
- Change toolchain as desired. Commit and push on changes
- Before submitting MR
  - use upstream `./libs/bash/install.sh ${BRANCH_NAME}`
  - run all the Jenkins stages locally
  - ensure CI pipeline is green
  - Execute `git commit` and `git push` on the upstream project to ensure git hooks execute properly

## Full pipeline execution on localhost

```sh
./libs/bash/install.sh
./libs/bash/install.sh --skip_iac_tools true --skip_misc_tools true --skip_system_tools true
./libs/bash/install.sh --skip_cloud_tools true --skip_misc_tools true --skip_system_tools true
./libs/bash/install.sh --skip_cloud_tools true --skip_iac_tools true --skip_system_tools true
./libs/bash/install.sh --skip_cloud_tools true --skip_iac_tools true --skip_misc_tools true
./libs/bash/install.sh --update true
```
