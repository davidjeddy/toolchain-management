#!/bin/bash

set -exo pipefail

function get_cmd_options() {
  declare VALID_ARGS

  local -n _SHORT_OPTS=$1
  local -n _LONG_OPTS=$2
  local -n _CMD_LINE_OPTS=$3
  if ! VALID_ARGS=$(getopt -n "$(basename "${0}")" -o "$(echo "${_SHORT_OPTS[@]}" | tr ' ' ',')" --long "$(echo "${_LONG_OPTS[@]}" | tr ' ' ',')" -- "${_CMD_LINE_OPTS[@]}"); then
    exit 1
  fi

  eval set -- "$VALID_ARGS"
  while true; do
    if [[ $1 == "--help" || $1 == "-h" ]]; then
      print_usage
      exit 0
    elif [[ $1 == "--" ]]; then
      shift
      break
    else
      for i in "${!_SHORT_OPTS[@]}"; do
        if [[ "-${_SHORT_OPTS[$i]//:/}" = "${1}" || "--${_LONG_OPTS[$i]//:/}" = "${1}" ]]; then
          key="${_LONG_OPTS[$i]//:/}"
          if [[ "${_LONG_OPTS[$i]}" == *: ]]; then
            # Argument has value
            declare -rg "${key^^}"="$2"
            shift
          else
            # Argument has no value (flag)
            declare -rg "${key^^}=true"
          fi
        fi
      done
    fi
    shift
  done

  # Get service_name
  export SERVICE_NAME="$1"

  # Fill missing variables with default values
  for i in "${!_LONG_OPTS[@]}"; do
    if [[ ${_LONG_OPTS[$i]} =~ ':'$ ]]; then
      key=${_LONG_OPTS[$i]//:/}
      key_upper="${key^^}"
      if [[ "${!key_upper}" == "" ]]; then
        default_var_name="DEFAULT_${key_upper}"
        declare -rg "${key_upper}"="${!default_var_name}"
      fi
    fi
  done
}

function logging_level() {
  if [[ $WL_TC_LOG_LEVEL == "TRACE" ]]
  then 
      set -x
  fi
}
