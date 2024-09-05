# RUNBOOK

## Operations

### Validate Changes

```sh
./libs/bash/install.sh --update true
```

Additionally, run the same command from a IAC shared module project directory.

```sh
git clone some-module
cd some-module
./libs/bash/install.sh --update true
```

Lastly, execute the above same via Jenkins to ensure end-to-end functionality.

## Errors, When, and Fixes

**Error**

An error occurred (InvalidClientTokenId) when calling the GetSessionToken operation: The security token included in the request is invalid.
16:22:11 - awscliv2 - ERROR - Command failed with code 254

**Fix** Generate API credentials in IAM for the user

-----

**Error**

An error occurred (AccessDenied) when calling the GetSessionToken operation: MultiFactorAuthentication failed, unable to validate MFA code.  Please verify your MFA serial number is valid and associated with this user.
16:28:50 - awscliv2 - ERROR - Command failed with code 254

**Fix** Check that you are providing the ARN of the TOKEN DEVICE, NOT the ARN of the IAM user.

**Fix** Remove and re-create IAM user MFA device. Be sure to not mix the new and old device on Virtual OTP or physical device.

-----

**Error**

Also:   org.jenkinsci.plugins.workflow.actions.ErrorAction$ErrorId: bd09a9fb-434a-4fb0-bd98-2bce7301e0a8
hudson.remoting.ProxyException: groovy.lang.MissingPropertyException: No such property: gitlabConnectionName for class: WorkflowScript

**When**

Executing pipeline

**Fix**

Ensure Jenkinsfile contains `gitlabConnectionName` variable and valid value.

-----

**Error**

ImportError: cannot import name 'run' from 'checkov.main' (/home/jenkins/.local/lib/python3.8/site-packages/checkov/main.py)

**When**

checkov --version

**Fix**

Remove the checkov binary. It is the wrong one. Re-install checkov via ./libs/bash/install.sh. Be sure `~/.worldline_pps_profile` is being sourced.

-----

**Error**

```sh
./libs/bash/language_runtimes.sh: line 53: goenv: command not found
./libs/bash/language_runtimes.sh: line 54: goenv: command not found
ERR: Failed to install Golang via goenv.
```

**When**

When executing `./libs/bash/install.sh` on Debian/Ubuntu based hosts.

**Fix**

Debian/Ubuntu adds a short-cuircity check in the users `~/.bashrc` that prevents sourcing it when accessed via a non-interactive process. This prevents the install script from reloading the $PATH value.

To correct this behavior edit your users `~/.bashrc` commenting out the check.

Before:

```sh
...
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac
...
```

After

```sh
...
# Commented out to enable Worldline GlobalCollect toolchain-management
# If not running interactively, don't do anything
# case $- in
#    *i*) ;;
#      *) return;;
# esac
...
```

Start a new shell session and the issue should not present itself any longer.

-----

**Error**

... doc="https://aquaproj.github.io/docs/reference/codes/001" env=linux/amd64 error="checksum is required" package_name=tgenv/tgenv package_version=v1.2.1 program=aqua registry=standard

**When**

aqua install

**Fix**

Reset aqua configuration back to known-good. Run install again.

-----

**Error**

[Pipeline] // script
[Pipeline] updateGitlabCommitStatus
 > git rev-parse HEAD^{commit} # timeout=10
[Pipeline] }
[Pipeline] // stage
[Pipeline] End of Pipeline
ERROR: null
Finished: FAILURE

**When**

Executing pipeline

**Fix**

Jenkinsfile `String gitlabProjectId` value does not match the ID in GitLab.

-----

**Error**

[Pipeline] End of Pipeline
ERROR: null
Finished: FAILURE

**When**

Pipeline is run

**Fix**

Check the usage of variables inside the pipeline.environment{} block. Specifically ensure the variable being used is indeed defined.

-----

**Error**

`INFO: This is taking longer than usual. You might need to provide the dependency resolver with stricter constraints to reduce runtime. See https://pip.pypa.io/warnings/backtracking for guidance. If you want to abort this run, press Ctrl + C.`

**When**

./libs/bash/install.sh

**Fix**

Just wait. Localstack requires a lot of packages and version contraint sorting.
