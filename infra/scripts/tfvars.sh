#!/bin/bash

# Enable debug mode with DEBUG=1
[ -z "$DEBUG" ] || set -x

MANIFESTS_DIR="$( cd "$( dirname "${BASH_SOURCE[1]}" )" >/dev/null 2>&1 && pwd )"


APP_NAME=${APP_NAME:-fluentd-aggregator}
AWS_REGION=${AWS_REGION:-ap-northeast-2}

PROJECT_NAME=$1
ENV=$2
CLIENT_NAME=${CLIENT_NAME:-${PROJECT_NAME}}

PROJECT_VPC_ID="$(aws ec2 describe-vpcs --filters Name=tag:Group,Values=${PROJECT_NAME} | jq -r '.Vpcs[].VpcId' )" || echo ""

VPC_ID="${VPC_ID:-$PROJECT_VPC_ID}"

TF_VARS_TPL=${MANIFESTS_DIR}/config/tfvars.tpl
TF_VARS_NEW=${MANIFESTS_DIR}/config/$PROJECT_NAME.$ENV.tfvars

TAG=${TAG:-latest}

if [ -z "$TEST_IMAGE" ]; then
	REPO_URL=$(aws ecr describe-repositories --repository-names "$APP_NAME" | jq ".repositories[].repositoryUri" | tr -d '"')
	CONTAINER_PORT=24224
else
	echo "set"
	REPO_URL="ziwon/go-app"
	CONTAINER_PORT=8080
fi


echo "Creating tfvars file.."
[ -f "$TF_VARS_NEW" ] && rm -f "$TF_VARS_NEW"

PROJECT_SLUG="${PROJECT_SLUG:-$PROJECT_NAME}"

sed "s/{{ REGION }}/${AWS_REGION}/; \
	s/{{ VPC_ID }}/${VPC_ID}/; \
	s/{{ APP_NAME }}/${APP_NAME}/; \
	s/{{ PROJECT_NAME }}/${PROJECT_SLUG:0:3}/; \
	s/{{ ENV }}/${ENV}/; \
	s/{{ CONTAINER_IMAGE }}/${REPO_URL//\//\\/}:${TAG}/; \
	s/{{ CONTAINER_PORT }}/${CONTAINER_PORT}/; \
	s/{{ CERTIFICATE_ARN }}/${CERTIFICATE_ARN}/; \
	s/{{ CLIENT_NAME }}/${CLIENT_NAME}/; \
	s/{{ KMS_ARN }}/${KMS_ARN}/; \
  s/{{ ES_HOST }}/${ES_HOST}/; \
  s/{{ ES_PORT }}/${ES_PORT}/; \
  s/{{ ES_USER }}/${ES_USER}/; \
  s/{{ ES_PASSWORD }}/${ES_PASSWORD}/; \
  s/{{ ES_SCHEME }}/${ES_SCHEME}/; \
  s/{{ ES_SSL_VERIFY }}/${ES_SSL_VERIFY}/;" \
	"$TF_VARS_TPL" > "$TF_VARS_NEW"
