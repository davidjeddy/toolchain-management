#!/bin/bash -e

# usage: /path/to/script/ecs_service_port_proxy.sh
#        /path/to/script/ecs_service_port_proxy.sh 
#        /path/to/script/ecs_service_port_proxy.sh keycloak
#        /path/to/script/ecs_service_port_proxy.sh -s keycloak
# example: /path/to/script/ecs_service_port_proxy.sh -c "snd-connect-shared-ecs-nygw" keycloak
# example: /path/to/script/ecs_service_port_proxy.sh -s "eu-west-1" gateway
# example: /path/to/script/ecs_service_port_proxy.sh -c "snd-connect-shared-ecs-nygw" -r "eu-central-1" keycloak
# example: /path/to/script/ecs_service_port_proxy.sh --cluster_name "snd-connect-shared-ecs-nygw" --region_name "eu-central-1" keycloak

## Default values
declare DEFAULT_CLUSTER_NAME
declare DEFAULT_REGION_NAME
declare DEFAULT_DB_HOST
declare DEFAULT_DB_PORT
declare DEFAULT_LOCAL_PORT
DEFAULT_CLUSTER_NAME="snd-connect-shared-ecs-nygw"
DEFAULT_REGION_NAME="eu-west-1"
DEFAULT_DB_HOST="snd-connect-oracle-nygw.c1l2uooswrzx.eu-west-1.rds.amazonaws.com"
DEFAULT_DB_PORT="1521"
DEFAULT_LOCAL_PORT="1521"

## Internal VARs
declare SERVICE_NAME
declare CLUSTER_NAME
declare REGION_NAME
declare DB_HOST
declare DB_PORT
declare LOCAL_PORT

declare LIST_TASK_ARN
declare TASK_DETAILS
declare TASK_ID
declare CONTAINER_RUNTIME_ID

declare SCRIPT_DIR
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# functions

function print_usage() {
  printf "\n"
  printf "Usage\n"
  printf "  %s [options] <service_name>\n" "$(basename "${0}")"
  printf "\n"
  printf "Options:\n"
  printf "  <service_name>                        The ECS service name to be used as a jump server\n"
  printf "  -c, --cluster_name <cluster_name>     ECS cluster name     (default: %s)\n" "${DEFAULT_CLUSTER_NAME}"
  printf "  -r, --region_name <region_name>       AWS region name      (default: eu-west-1. Currently: %s)\n" "${DEFAULT_REGION_NAME}"
  printf "  -H, --db_host <db_host>               Database host name   (default: %s)\n" "${DEFAULT_DB_HOST}"
  printf "  -P, --db_port <db_port>               Database port number (default: %s)\n" "${DEFAULT_DB_PORT}"
  printf "  -l, --local_port <local_port>         Local port number    (default: %s)\n" "${DEFAULT_LOCAL_PORT}"
  printf "  -h, --help                            print help and exit\n"
  printf "\n"
}

#shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/get_cmd_options.sh" || exit 1

# shellcheck disable=SC2034 # We use the value to call get_cmd_options
SHORT_OPTS=("h" "c:" "r:" "H:" "P:" "l:")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
LONG_OPTS=("help" "cluster_name:" "region_name:" "db_host:" "db_port:" "local_port:")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
CMD_LINE_ARGS=("$@")

get_cmd_options SHORT_OPTS LONG_OPTS CMD_LINE_ARGS

if [[ "$SERVICE_NAME" == "" ]]; then
  printf "ERR: no service_name provided. Exiting with error.\n"
  print_usage
  exit 1
fi

# execute ecs requests

# shellcheck disable=SC2207
LIST_TASK_ARN=( $(aws ecs list-tasks \
  --region "${REGION_NAME}" \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --query 'taskArns' \
  --output text) )
TASK_DETAILS=$(aws ecs describe-tasks \
  --region "${REGION_NAME}" \
  --cluster "$CLUSTER_NAME" \
  --tasks "${LIST_TASK_ARN[@]}" \
  --query "tasks[] | sort_by(@, &startedAt) | [-1].[taskArn, containers[?starts_with(name, \`fluent-bit\`) == \`false\` && starts_with(name, \`smtp-relay\`) == \`false\` && starts_with(name, \`install-oneagent\`) == \`false\`].runtimeId]" \
  --output text)
TASK_ID=$(echo "$TASK_DETAILS" | sed '1p;d' | cut -d "/" -f 3)
CONTAINER_RUNTIME_ID=$(echo "$TASK_DETAILS" | sed '2p;d')

# forward local port

printf "\nLocal port is: %s\n" "${LOCAL_PORT}"

aws ssm start-session \
  --target "ecs:${CLUSTER_NAME}_${TASK_ID}_${CONTAINER_RUNTIME_ID}" \
  --region "${REGION_NAME}" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters host="${DB_HOST}",portNumber="${DB_PORT}",localPortNumber="${LOCAL_PORT}"
