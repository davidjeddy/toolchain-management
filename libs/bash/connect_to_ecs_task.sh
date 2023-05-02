#!/bin/bash -e

## Default values
declare DEFAULT_CLUSTER_NAME
declare DEFAULT_REGION_NAME
declare DEFAULT_SELECT_TASK
DEFAULT_CLUSTER_NAME="snd-connect-shared-ecs-nygw"
DEFAULT_REGION_NAME=$(aws configure get region)
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
declare CHOICE

# functions

function print_usage() {
  printf "\n"
  printf "Usage\n"
  printf "  %s [options] <service_name>\n" "$(basename "${0}")"
  printf "\n"
  printf "Options:\n"
  printf "  <service_name>                        the ECS service name\n"
  printf "  -c, --cluster_name <cluster_name>     ECS cluster name (default: %s)\n" "${DEFAULT_CLUSTER_NAME}"
  printf "  -r, --region_name <region_name>       AWS region name  (default: aws cli configured region. Currently: %s)\n" "${DEFAULT_REGION_NAME}"
  printf "  -s, --select_task                     when there are multiple tasks, list them for user to select (default: %s)\n" "${DEFAULT_SELECT_TASK}"
  printf "  -h, --help                            print help and exit\n"
  printf "\n"
}

source get_cmd_options.sh

# shellcheck disable=SC2034 # We use the value to call get_cmd_options
SHORT_OPTS=("h" "c:" "r:" "s")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
LONG_OPTS=("help" "cluster_name:" "region_name:" "select_task")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
CMD_LINE_ARGS=("$@")

get_cmd_options SHORT_OPTS LONG_OPTS CMD_LINE_ARGS

# execution logic

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

# connect to the ecs instance
aws ecs execute-command \
  --region "${REGION_NAME}" \
  --cluster "${CLUSTER_NAME}" \
  --container "${SERVICE_NAME}" \
  --command "/bin/sh" \
  --interactive \
  --task "${TASK_ID}"
