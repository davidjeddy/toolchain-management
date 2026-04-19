#!/bin/bash -l

# set -exo pipefail # when debugging
set -eo pipefail

# Enforce the session load like an interactive user
# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# Process:
# get author email
#  - if commit msg contains "Merge branch"
#    - look at prev. commit
# extract email
# search slack api for user scoped by email
#  - Slack Credentials provided by Jenkins credentials helper loaded into ENV VARs
# DM user msg the build failed
#
# example ./libs/bash/slack_dm_commit_author_on_main_build_failiure.sh
# usage ./libs/bash/slack_dm_commit_author_on_main_build_failiure.sh
# version: 0.1.0  - 2025-08-11

# return the email of the most recent commit that does NOT contaioner "Merge Branch"
declare COMMIT_AUTHOR
COMMIT_AUTHOR=$(git log --format='%ae' --invert-grep --grep='Merge\ branch' --max-count 1)
printf "INFO: COMMIT_AUTHOR = %s\n" "${COMMIT_AUTHOR}"

# search slack via API for a user with the email
# https://api.slack.com/methods/users.lookupByEmail
declare SLACK_RESPONSE
SLACK_RESPONSE=$(curl \
    --header "Authorization: Bearer ${SLACK_OAUTH_TOKEN_WL_GC_IAC_BUILD_FAILURE}" \
    --header "Content-type: application/json" \
    --location \
    "https://slack.com/api/users.lookupByEmail?email=${COMMIT_AUTHOR}")
printf "INFO: SLACK_RESPONSE = %s\n" "${SLACK_RESPONSE}"

# If user ID does not start with
if [[ ${SLACK_RESPONSE} == *"false"* ]]
then
    printf "ERR: Slack repsonse contains a failure response:\n%s\n" "${SLACK_USER_ID}"
    exit 1
fi

declare SLACK_USER_ID
SLACK_USER_ID=$(echo "${SLACK_RESPONSE}" | jq -M .user.id)
printf "INFO: SLACK_USER_ID = %s\n" "${SLACK_USER_ID}"

# If user ID does not start with
if [[ ${SLACK_USER_ID} == "" ]]
then
    printf "ERR: Slack user not found! Please check response from Slack:\n%s\n" "${SLACK_USER_ID}"
    exit 1
fi

declare JSON_STRING
JSON_STRING='{
    "channel": '${SLACK_USER_ID}',
    "text": ":warning: You recent merged changes to th emain branch of the IAC deploymentrs project. The pipeline iteration returned a non-zero (error exist) exit code. Please review the output and correct as needed. "'${BUILD_URL}'
}'
printf "INFO: JSON_STRing = %s\n" "${JSON_STRING}"

# Send DM regarding failed biuld
curl \
    --header "Authorization: Bearer ${SLACK_OAUTH_TOKEN_WL_GC_IAC_BUILD_FAILURE}" \
    --header "Content-type: application/json; charset=utf-8" \
    --request POST \
    --data "${JSON_STRING}" \
    "https://slack.com/api/chat.postMessage"
