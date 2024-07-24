#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage: /path/to/script/ecs_service_port_proxy.sh
#        /path/to/script/ecs_service_port_proxy.sh 
#        /path/to/script/ecs_service_port_proxy.sh keycloak
#        /path/to/script/ecs_service_port_proxy.sh -s keycloak
# example: /path/to/script/ecs_service_port_proxy.sh -c "snd-connect-shared-ecs-nygw" keycloak
# example: /path/to/script/ecs_service_port_proxy.sh -s "eu-west-1" gateway
# example: /path/to/script/ecs_service_port_proxy.sh -c "snd-connect-shared-ecs-nygw" -r "eu-central-1" keycloak
# example: /path/to/script/ecs_service_port_proxy.sh --cluster_name "snd-connect-shared-ecs-nygw" --region "eu-central-1" keycloak

# example: Accessing Active MQ web UI via ops-tooling ECS service:
# ./ecs_service_port_proxy.sh \
#   --aws_region eu-west-1 \
#   --cluster_name ppd-connect-shared-ecs-msc7 \
#   --local_port 8163 \
#   --target_host_dns "b-ceac76ed-2493-4683-b735-977e5762b46f-1.mq.eu-west-1.amazonaws.com" \
#   --target_host_port 8162 \
#   ops-tooling

## Preflight

if [[ ! $AWS_PROFILE ]]
then
  printf "ERR: Please authenticate via OneLogin CLI before attempting to connect.\n"
  exit 1
fi

## Variables

declare AWS_REGION
declare CLUSTER_NAME
declare CONTAINER_ID
declare LIST_SERVICE_TASK_ARN
declare LOCAL_PORT
declare SCRIPT_DIR
declare SERVICE_NAME
declare TARGET_HOST_DNS
declare TARGET_HOST_PORT
declare TASK_DETAILS
declare TASK_ID


## Set Defaults

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

## Functions

function help() {
  printf "\n"
  printf "Usage\n"
  printf "  %s [options] <service_name>\n" "$(basename "${0}")"
  printf "\n"
  printf "CLI arguments:\n"
  printf "  -c, --cluster_name <cluster_name>\n"
  printf "  -r, --aws_region <aws_region>\n"
  printf "  -H, --target_host_dns <target_host_dns>\n"
  printf "  -P, --target_host_port <target_host_port>\n"
  printf "  -l, --local_port <local_port>\n"
  printf "  -h, --help\n"
  printf "<service_name> The ECS service to be used as a jump host\n"
  printf "\n"
}

## Libraries

#shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/get_cmd_options.sh" || exit 1

## Logic

# shellcheck disable=SC2034 # We use the value to call get_cmd_options
SHORT_OPTS=("h" "c:" "r:" "H:" "P:" "l:")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
LONG_OPTS=("help" "cluster_name:" "aws_region:" "target_host_dns:" "target_host_port:" "local_port:")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
CMD_LINE_ARGS=("$@")

get_cmd_options SHORT_OPTS LONG_OPTS CMD_LINE_ARGS

if [[ "$SERVICE_NAME" == "" ]]; then
  printf "ERR: no service_name provided. Exiting with error.\n"
  help
  exit 1
fi

# execute ecs requests

# shellcheck disable=SC2207
LIST_SERVICE_TASK_ARN=($(
  aws ecs list-tasks \
    --cluster "${CLUSTER_NAME}" \
    --output text \
    --query 'taskArns' \
    --region "${AWS_REGION}" \
    --service-name "${SERVICE_NAME}"
))

printf "INFO: LIST_SERVICE_TASK_ARN(s) is %s\n" "${LIST_SERVICE_TASK_ARN[@]}"

TASK_DETAILS=$(
  aws ecs describe-tasks \
    --cluster "${CLUSTER_NAME}" \
    --output text \
    --query "tasks[] | sort_by(@, &startedAt) | [-1].[taskArn, containers[?starts_with(name, \`fluent-bit\`) == \`false\` && starts_with(name, \`smtp-relay\`) == \`false\` && starts_with(name, \`install-oneagent\`) == \`false\`].runtimeId]" \
    --region "${AWS_REGION}" \
    --tasks "${LIST_SERVICE_TASK_ARN[@]}"
)

printf "INFO: TASK_DETAILS is %s\n" "${TASK_DETAILS}"

TASK_ID=$(echo "$TASK_DETAILS" | sed '1p;d' | cut -d "/" -f 3)

printf "INFO: TASK_ID is %s\n" "${TASK_ID}"

CONTAINER_ID=$(echo "${TASK_DETAILS}" | sed '2p;d' | cut -f 2)

printf "INFO: CONTAINER_ID is %s\n" "${CONTAINER_ID}"

# forward local port

printf "\nLocal port %s proxied via service %s container id %s to remote host dns %s on remote port %s\n" "${LOCAL_PORT}" "${SERVICE_NAME}" "${CONTAINER_ID}" "${TARGET_HOST_DNS}" "${TARGET_HOST_PORT}"

aws ssm start-session \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters host="${TARGET_HOST_DNS}",portNumber="${TARGET_HOST_PORT}",localPortNumber="${LOCAL_PORT}" \
  --region "${AWS_REGION}" \
  --target "ecs:${CLUSTER_NAME}_${TASK_ID}_${CONTAINER_ID}"
