#!/bin/bash -e

# usage ./libs/ecs_update_service_task NAME_OF_THE_CLUSTER REGION "NEWLINE DELIMITED LIST OF SERVICE NAMES"
# example ./libs/ecs_update_service_task "snd-connect-shared-ecs-nygw" "eu-west-1" "terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/admin-tool
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/api-explorer
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/auth-service 
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/config-center
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/email-service
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/file-service
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/gateway
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/hazelcast
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/hello-internal
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/hello-world
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/iin
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/orchestration
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/redirector
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/rpp
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/rpp-vm
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/webhooks-filter
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/webhooks-management
# terraform/aws/aws-ingenico-globalcollect-dev/eu-west-1/connect/nygw/ecs-services/webhooks-notifier"

echo "WARN: Cycling all services in the $1 cluster."

CLUSTER=$1
REGION=$2
SERVICES=$3

PRJ_ROOT="$(pwd)"

for SERVICE in $SERVICES
do
    echo "INFO: Change into ECS service module $SERVICE."
    cd "$SERVICE" || exit 1

    echo "INFO: Running Terraform to ensure module is up to date."
    terraform init;
    terraform apply --auto-approve;
    
    echo "INFO: Cycle service task."
    aws ecs update-service \
        --cluster "$CLUSTER" \
        --no-cli-pager \
        --region "$REGION" \
        --service "$(basename "$SERVICE")"

    cd "$PRJ_ROOT" || exit 2
done

echo "INFO: Done."
