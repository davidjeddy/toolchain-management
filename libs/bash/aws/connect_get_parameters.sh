#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage: /path/to/script/connect_get_parameters.sh
#        /path/to/script/connect_get_parameters.sh -l
#        /path/to/script/connect_get_parameters.sh api-explorer
# example: /path/to/script/connect_get_parameters.sh -c "int-connect-shared-ecs-klm8" api-explorer
# example: /path/to/script/connect_get_parameters.sh -s "eu-west-1" api-explorer
# example: /path/to/script/connect_get_parameters.sh -c "int-connect-shared-ecs-klm8" -r "eu-west-1" api-explorer
# example: /path/to/script/connect_get_parameters.sh --cluster_name "int-connect-shared-ecs-klm8" --region_name "eu-west-1" api-explorer

## Default values
declare DEFAULT_CLUSTER_NAME
declare DEFAULT_REGION_NAME
DEFAULT_CLUSTER_NAME="int-connect-shared-ecs-klm8"
DEFAULT_REGION_NAME="eu-west-1"

## Internal VARs
declare SERVICE_NAME
declare CLUSTER_NAME
declare REGION_NAME

declare SHORT_OPTS
declare LONG_OPTS
declare CMD_LINE_ARGS
declare LIST_SERVICES
declare ENVIRONMENT

declare SCRIPT_DIR
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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
  printf "  -h, --help                            print help and exit\n"
  printf "\n"
}

#shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/get_cmd_options.sh" || exit 1

# shellcheck disable=SC2034 # We use the value to call get_cmd_options
SHORT_OPTS=("h" "l" "c:" "r:")
# shellcheck disable=SC2034 # We use the value to call get_cmd_options
LONG_OPTS=("help" "list_services" "cluster_name:" "region_name:")
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

ENVIRONMENT=(${CLUSTER_NAME//-/ })

readarray -t PARAMETER_NAMES < <(aws ssm describe-parameters \
  --query "Parameters[?starts_with(Name, '/${ENVIRONMENT[0]}/connect/${SERVICE_NAME}/')]" \
  --output json \
  --region "${REGION_NAME}" | jq -r -c '.[].Name')

MAX_LENGTH=0
for PARAMETER in "${PARAMETER_NAMES[@]}"; do
  length=${#PARAMETER}
  if ((length > MAX_LENGTH)); then
    MAX_LENGTH=$length
  fi
done

is_json() {
  echo "$1" | jq . >/dev/null 2>&1
  return $?
}

pad_line() {
  PAD="$1"
  FIRST=true
  while IFS= read -r LINE; do
    if [ "$FIRST" = true ]; then
      printf "%s\n" "$LINE"
      FIRST=false
    else
      printf "%s%s\n" "$PAD" "$LINE"
    fi
  done
}

for PARAMETER in "${PARAMETER_NAMES[@]}"; do
  VALUE=$(aws ssm get-parameter \
    --name "$PARAMETER" --query "Parameter.Value" \
    --output text \
    --region "${REGION_NAME}")

  STATUS=$?

  if [[ $STATUS -eq 0 ]]; then
    if is_json "$VALUE"; then
      FORMATTED=$(echo "$VALUE" | jq . | pad_line "$(printf "%-${MAX_LENGTH}s : """)")
    else
      FORMATTED="$VALUE"
    fi
    printf "%-${MAX_LENGTH}s : %s\n" "$PARAMETER" "$FORMATTED"
  else
    printf "%-${MAX_LENGTH}s : %s\n" "$PARAMETER" "Error retrieving parameter"
  fi
done
