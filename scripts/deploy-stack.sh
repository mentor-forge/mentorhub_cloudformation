#!/usr/bin/env bash
# Deploy a CloudFormation stack.
# Usage: ./scripts/deploy-stack.sh <environment> <component> <aws-profile> [extra deploy args...]
#
# Examples:
#   ./scripts/deploy-stack.sh shared-services ecr mentorhub-shared
#   ./scripts/deploy-stack.sh dev network mentorhub-dev --no-fail-on-empty-changeset

set -euo pipefail

ENV="${1:?environment required (shared-services|dev|staging|production)}"
COMPONENT="${2:?component required (e.g. ecr, network)}"
PROFILE="${3:?AWS profile required}"
shift 3 || true

STACK_NAME="mentorhub-${ENV}-${COMPONENT}"
TEMPLATE="templates/${ENV}/${COMPONENT}.yaml"
PARAMS="parameters/${ENV}.json"
REGION="${AWS_REGION:-us-east-1}"

if [[ ! -f "${TEMPLATE}" ]]; then
  echo "Template not found: ${TEMPLATE}" >&2
  exit 1
fi

DEPLOY_ARGS=(
  --stack-name "${STACK_NAME}"
  --template-file "${TEMPLATE}"
  --region "${REGION}"
  --profile "${PROFILE}"
  --tags "Project=MentorHub" "Environment=${ENV}" "ManagedBy=CloudFormation"
  --capabilities CAPABILITY_NAMED_IAM
)

if [[ -f "${PARAMS}" ]]; then
  DEPLOY_ARGS+=(--parameter-overrides "file://${PARAMS}")
fi

echo "Deploying ${STACK_NAME} from ${TEMPLATE} (profile=${PROFILE}, region=${REGION})"
aws cloudformation deploy "${DEPLOY_ARGS[@]}" "$@"
