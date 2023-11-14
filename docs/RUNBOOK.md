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

Remove the checkov binary. It is the wrong one. Re-install checkov via ./libs/bash/install.sh. Be sure the "$HOME/.worldline_pps_profile" is being sourced.
