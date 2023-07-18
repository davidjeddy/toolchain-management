#!/bin/bash


# Pass all arguments to oneline CLI
onelogin-aws-login -C worldline-gc-keycloak-staging

# if the output has `--profile` use the next word string as a value

# export in parent shell as AWS_DEFAULT_PROFILE
export AWS_DEFAULT_PROFILE=$PROFILE_STRING
