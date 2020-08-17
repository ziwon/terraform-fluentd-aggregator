#!/bin/bash

OUTPUT_FILE=taskdef.json

TASK_NAME=$1
BUCKET_NAME=$2
CPU=$3
MEMORY=$4
TASK_ROLE_ARN=$5
EXE_ROLE_ARN=$6

[ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"

aws ecs describe-task-definition --task-definition="${TASK_NAME}" \
	| jq '.taskDefinition|{family, containerDefinitions}' \
	| jq 'del(.containerDefinitions[0].mountPoints)' \
	| jq 'del(.containerDefinitions[0].volumesFrom)' \
	| jq '.containerDefinitions[0].image = "<IMAGE1>"' \
	| jq '.cpu ="'"${CPU}"'" | .memory="'"${MEMORY}"'"' \
	| jq '.requiresCompatibilities=["FARGATE"]' \
	| jq '.networkMode="awsvpc"' \
	| jq '.taskRoleArn="'"${TASK_ROLE_ARN}"'"' \
	| jq '.executionRoleArn="'"${EXE_ROLE_ARN}"'"' > "$OUTPUT_FILE"

aws s3 cp taskdef.json s3://"${BUCKET_NAME}/taskdef.json"
aws s3 cp appspec.yml s3://"${BUCKET_NAME}/appspec.yml"

[ ! -z "$DEBUG" ] || rm -f taskdef.json
