# RUNBOOK

## ./libs/bash/sgets_aws_sts_token.sh

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
