#!/bin/bash

# usage: /path/to/script/tail_log.sh
#        /path/to/script/tail_log.sh -l
#        /path/to/script/tail_log.sh gateway
#        /path/to/script/tail_log.sh -s hazelcast
# example: /path/to/script/tail_log.sh -c "snd-connect-shared-ecs-nygw" gateway
# example: /path/to/script/tail_log.sh -s "eu-west-1" gateway
# example: /path/to/script/tail_log.sh -c "snd-connect-shared-ecs-nygw" -r "eu-west-1" gateway
# example: /path/to/script/tail_log.sh --cluster_name "snd-connect-shared-ecs-nygw" --region_name "eu-west-1" gateway

## Default values
declare DEFAULT_CLUSTER_NAME
declare DEFAULT_REGION_NAME
declare DEFAULT_SELECT_TASK
DEFAULT_CLUSTER_NAME="snd-connect-shared-ecs-nygw"
DEFAULT_REGION_NAME="eu-west-1"
DEFAULT_SELECT_TASK="false"

## Internal VARs
declare SERVICE_NAME
declare CLUSTER_NAME
declare REGION_NAME
declare SELECT_TASK

declare SHORT_OPTS
declare LONG_OPTS
declare CMD_LINE_ARGS
declare LIST_TASK_ARN
declare NUMBER_OF_ARNS
declare TASK_ARN
declare TASK_ID
declare LIST_SERVICES
declare CHOICE
declare LOG_STREAM
declare LOG_GROUP_JSON
declare NUMBER_OF_RESULTS

# functions

function print_usage() {
  printf "\n"
  printf "Usage\n"
  printf "  %s [options] <service_name>\n" "$(basename "${0}")"
  printf "\n"
  printf "Options:\n"
  printf "  <service_name>                        the ECS service name\n"
  printf "  -l, --list_services                   list the services available and exit\n"
  printf "  -c, --cluster_name <cluster_name>     ECS cluster name (default: %s)\n" "${DEFAULT_CLUSTER_NAME}"
  printf "  -r, --region_name <region_name>       AWS region name  (default: aws cli configured region. Currently: %s)\n" "${DEFAULT_REGION_NAME}"
  printf "  -s, --select_task                     when there are multiple tasks, list them for user to select (default: %s)\n" "${DEFAULT_SELECT_TASK}"
  printf "  -h, --help                            print help and exit\n"
  printf "\n"
}

source get_cmd_options.sh

# shellcheck disable=SC2034 # We use the value to call get_cmd_options
SHORT_OPTS=("h" "l" "c:" "r:" "s")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
LONG_OPTS=("help" "list_services" "cluster_name:" "region_name:" "select_task")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
CMD_LINE_ARGS=("$@")

get_cmd_options SHORT_OPTS LONG_OPTS CMD_LINE_ARGS

# execution logic
if [[ "${LIST_SERVICES}" =~ "true" ]]; then
  printf %s "$(aws ecs list-services \
    --region "${REGION_NAME}" \
    --cluster "${CLUSTER_NAME}" \
    --output text)" | cut -d "/" -f 3
  exit 0
fi

if [[ "$SERVICE_NAME" == "" ]]; then
  printf "ERR: no service_name provided. Exiting with error.\n"
  print_usage
  exit 1
fi

# execute ecs requests
# shellcheck disable=SC2207
LIST_TASK_ARN=($(aws ecs list-tasks \
  --region "${REGION_NAME}" \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --query 'taskArns' \
  --output text))
NUMBER_OF_ARNS="${#LIST_TASK_ARN[@]}"

if ((NUMBER_OF_ARNS == 0)); then
  echo "Task not found for cluster $CLUSTER_NAME, service $SERVICE_NAME" && exit 1
elif ((NUMBER_OF_ARNS == 1)); then
  TASK_ARN="${LIST_TASK_ARN[0]}"
else
  if [[ "${SELECT_TASK}" =~ "true" ]]; then
    printf "Select the task you want to connect to:\n"
    select CHOICE in "${LIST_TASK_ARN[@]}"; do
      # shellcheck disable=SC2076
      if [[ " ${LIST_TASK_ARN[*]} " =~ " ${CHOICE} " ]]; then
        TASK_ARN=${CHOICE}
        break
      else
        printf "Invalid task selected, try again.\n"
      fi
    done
  else
    TASK_ARN=$(aws ecs describe-tasks \
      --region "${REGION_NAME}" \
      --cluster "$CLUSTER_NAME" \
      --tasks "${LIST_TASK_ARN[@]}" \
      --query "tasks[] | sort_by(@, &startedAt) | [-1].[taskArn]" \
      --output text)
  fi
fi

TASK_ID="$(echo "$TASK_ARN" | cut -d "/" -f 3)"

LOG_STREAM=snd/"${SERVICE_NAME}"/"${TASK_ID}"

LOG_GROUP_JSON=$(aws logs describe-log-streams --log-group-name "${CLUSTER_NAME}" \
  --log-stream-name-prefix "${LOG_STREAM}" \
  --output json)

readarray -t LOG_STREAMS < <(echo "${LOG_GROUP_JSON}" | jq -r -c '.logStreams[]')

NUMBER_OF_RESULTS="${#LOG_STREAMS[@]}"

if [ "${NUMBER_OF_RESULTS}" != 1 ]; then
  LOG_STREAM=snd/"${SERVICE_NAME}"-firelens-"${TASK_ID}"
fi

printf "Log stream name: %s\n" "${LOG_STREAM}"

aws logs tail "$CLUSTER_NAME" \
  --region "${REGION_NAME}" \
  --follow \
  --log-stream-name-prefix "${LOG_STREAM}"
