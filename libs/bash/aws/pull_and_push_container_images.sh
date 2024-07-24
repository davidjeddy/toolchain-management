#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# usage: pull_and_push_container_images.sh $AWS_ACCT_ID $AWS_REGION $ENV $APP $RND_STR $IMAGE_SOURCES()
# example: pull_and_push_container_images.sh 730335529266 eu-west-1 dev toolbox kmsd "podman.io/jenkins/jenkins:2.440.2-lts-jdk17"
# example: pull_and_push_container_images.sh 730335529266 eu-west-1 dev toolbox kmsd "podman.io/jenkins/jenkins:2.440.2-lts-jdk17=jenkins-controller, podman.io/alpine:3.19.1=ops-tooling, podman.io/library/sonarqube:9.9.4-community=sonarqube podman.io/sonatype/nexus3:3.67.0=nexus"
# example: pull_and_push_container_images.sh 730335529266 eu-west-1 dev toolbox kmsd "podman.io/sonatype/nexus3:3.67.0=nexus"

# Version: 0.1.1 - 2014-03-28

## execution configuration

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

## pre-flight

if [[ ! $(podman) ]]
then 
    printf "ERR: This process required the podman CLI tool.\n"
    exit 1;
fi

if [[ ! $AWS_PROFILE ]]
then 
    printf "ERR: Please provide target AWS account via \$AWS_PROFILE ENV VAR\.\n"
    exit 1;
fi


if [[ ! -f "/run/user/1000/containers/auth.json" ]]
then 
    printf "ERR: Please ensure you have authenticated to a remote image repository before running this process.\n"
    exit 1;
fi

## variable assignments

declare AWS_ACCT_ID
AWS_ACCT_ID="${1}"

declare AWS_REGION
AWS_REGION="${2}"

declare ENV
ENV="${3}"

declare APP
APP="${4}"

declare RND_STR
RND_STR="${5}"

declare IMAGE_CONFIGS
IFS=', ' read -ra IMAGE_CONFIGS <<< "${6}"

## Config output

printf "INFO: ENV VAR configurations:\n"

printf "INFO: APP: %s\n" "$APP"
printf "INFO: AWS_ACCT_ID: %s\n" "$AWS_ACCT_ID"
printf "INFO: AWS_REGION: %s\n" "$AWS_REGION"
printf "INFO: ENV: %s\n" "$ENV"
printf "INFO: RND_STR: %s\n" "$RND_STR"
for IMAGE_CONFIG in "${IMAGE_CONFIGS[@]}"
do
  printf "INFO: IMAGE_SOURCE: %s\n" "$IMAGE_CONFIG"
done

## functions

getSrvName() {
  # podman.io/jenkins/jenkins:2.440.2-lts-jdk17 # split on :
  # podman.io/jenkins/jenkins # split on /, keep last
  # jenkins # is the service name

  local SRV_NAME_0
  SRV_NAME_0=$(echo "$1" | awk -F ':' '{print $1}')
  # printf "INFO: Step 1 extracting SRV_NAME from %s\n" "$SRV_NAME_0"
  
  local SRV_NAME_1
  SRV_NAME_1=$(echo "$SRV_NAME_0" | awk -F '/' '{print $NF}')
  # printf "INFO: Step 2 extracting SRV_NAME from %s\n" "$SRV_NAME_1"

  echo "$SRV_NAME_1"
}

## execution

### Auth to target AWS ECR
aws ecr get-login-password \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  | podman login \
    --username AWS \
    --password-stdin "$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

for IMAGE_CONFIG in "${IMAGE_CONFIGS[@]}"
do
  printf "INFO: Processing image configuration: %s\n" "$IMAGE_CONFIG"

  declare IMAGE
  IMAGE=$(echo "$IMAGE_CONFIG" | awk -F '=' '{print $1}')
  declare TARGET_SRV_NAME
  TARGET_SRV_NAME=$(echo "$IMAGE_CONFIG" | awk -F '=' '{print $2}')
  printf "INFO: Split source image and target service name: %s %s\n" "$IMAGE" "$TARGET_SRV_NAME"

  podman pull "$IMAGE" --arch amd64

  # declare IMAGE_HASH
  IMAGE_HASH=$(podman inspect "$IMAGE" | jq -rM '.[].Id')

  # Tag image in prep for push
  declare TARGET_REPO
  TARGET_REPO="$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ENV/$APP/$TARGET_SRV_NAME/$RND_STR"
  printf "INFO: TARGET_REPO is %s\n" "$TARGET_REPO"

  # Tag with target repo name
  declare IMAGE_TAG
  IMAGE_TAG=$(echo "$IMAGE" | awk -F ':' '{print $2}')
  printf "INFO: IMAGE_TAG is %s\n" "$IMAGE_TAG"

  # tag image with new repo
  podman tag "$IMAGE_HASH" "$TARGET_REPO:$IMAGE_TAG"
  podman image list

  # Push image to AWS ECR
  {
    podman push "$TARGET_REPO:$IMAGE_TAG"
  } || {
    printf "WARN: Unable to push to target registry.\n"
  }
done

printf "INFO: ...Done.\n"
