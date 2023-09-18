#!/bin/bash -e

# example /home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management/libs/bash/iac/cycle_modules.sh
# usage   /home/david/Projects/Worldline/gitlab.test.igdcs.com/cicd/terraform/tools/toolchain-management/libs/bash/iac/cycle_modules.sh

# sources

declare SCRIPT_DIR
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/get_cmd_options.sh" || exit 1

# configuration

## Logging Level
logging_level

# pre-flight checks

if [[ ! $(which parallel) &&! $(which tree) ]]
then
  echo "ERR: This script requires 'parallel' and  'tree' CLI tool. Please install via your package manager."
fi

if [[ "$(pwd)" != *"ecs-services" ]]
then
  echo "ERROR: This scripts must be executed from a deployment ./ecs-services directory. Exiting with error."
  exit 1;
fi

# logic

echo "INFO: Starting..."

# https://opensource.com/article/18/5/gnu-parallel
tree -di --prune --sort name | parallel -j5 -I% "\
if [[ ! -d $(pwd)/% || ! -f $(pwd)/%/terraform.tf ]]; \
then \
  echo \"WARN: % not found or not a terraform module, skipping.\"
  exit 0; \
fi; \
cd $(pwd)/%; \
terraform init -no-color | tee init.log; \
terraform plan -no-color | tee plan.log; \
terraform apply --auto-approve -no-color | tee plan.log; \
"

echo "INFO: ...done."
