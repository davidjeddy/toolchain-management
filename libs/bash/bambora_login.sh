#!/bin/bash -ex

# $1 Bambora Onelogin MFA Code
# $2 Bambora managed AWS account alias

onelogin-aws-login -C $2
response =$($1 [ENTER])
export AWS_PROFILE=047788714173/admin/david.eddy@worldline.com

echo "Auth successful for Bambora mamanged AWS account alias ${2}."
