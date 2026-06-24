#!/usr/bin/env bash
# Import existing CodeArtifact domain and repositories into CloudFormation (R020).
#
# Prerequisites:
#   aws sso login --profile mentorhub-shared
#
# Usage:
#   ./scripts/import-codeartifact-stack.sh preflight     # read-only: live CodeArtifact vs template (Developer-Packages OK)
#   ./scripts/import-codeartifact-stack.sh plan          # create import change set (review only; requires SRE + CloudFormation)
#   ./scripts/import-codeartifact-stack.sh execute       # execute the latest IMPORT change set
#   ./scripts/import-codeartifact-stack.sh validate      # lint + validate-template only
#   ./scripts/import-codeartifact-stack.sh smoke         # post-import CLI checks (R020.6)
#   ./scripts/import-codeartifact-stack.sh apply-tags    # post-import resource tags (R020.5)
#
# Profile: default mentorhub-shared. Import plan/execute requires SRE permission set on Shared-Services
# (Developer-Packages is read-only for CodeArtifact — not CloudFormation). Override: AWS_PROFILE=...
#
# Import is non-destructive. Resources are retained on stack deletion (DeletionPolicy: Retain).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

STACK_NAME="mentorhub-shared-services-codeartifact"
TEMPLATE="templates/shared-services/codeartifact.yaml"
PARAMS="parameters/shared-services.json"
IMPORT_RESOURCES="import/codeartifact-resources-to-import.json"
PROFILE="${AWS_PROFILE:-mentorhub-shared}"
REGION="${AWS_REGION:-us-east-1}"
CHANGE_SET_PREFIX="import-codeartifact"

aws_cmd() {
  aws --profile "${PROFILE}" --region "${REGION}" "$@"
}

require_cloudformation() {
  if ! aws_cmd cloudformation validate-template --template-body "file://${TEMPLATE}" >/dev/null 2>&1; then
    echo "ERROR: CloudFormation access required (plan/execute/validate)." >&2
    echo "  Current profile: ${PROFILE}" >&2
    echo "  Use Shared-Services SSO role SRE (not Developer-Packages)." >&2
    echo "  Example: AWS_PROFILE=mentorhub-shared-sre ./scripts/import-codeartifact-stack.sh plan" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Required file not found: $1" >&2
    exit 1
  fi
}

preflight_check() {
  require_file "${TEMPLATE}"
  echo "==> Caller identity (${PROFILE})"
  aws_cmd sts get-caller-identity

  echo ""
  echo "==> Live CodeArtifact vs template (import targets)"
  local expected_kms="arn:aws:kms:${REGION}:560167829275:key/1cccc7d9-0b63-45e3-8ca8-655a755bf295"
  local live_kms
  live_kms="$(aws_cmd codeartifact describe-domain \
    --domain mentor-forge \
    --query 'domain.encryptionKey' \
    --output text)"
  if [[ "${live_kms}" == "${expected_kms}" ]]; then
    echo "  Domain mentor-forge KMS key: OK"
  else
    echo "  Domain mentor-forge KMS key: MISMATCH" >&2
    echo "    expected: ${expected_kms}" >&2
    echo "    live:     ${live_kms}" >&2
    exit 1
  fi

  for spec in "mentorhub-pypi|public:pypi" "mentorhub-npm|public:npmjs"; do
    local repo="${spec%%|*}"
    local conn="${spec##*|}"
    local live_conn
    live_conn="$(aws_cmd codeartifact describe-repository \
      --domain mentor-forge \
      --domain-owner 560167829275 \
      --repository "${repo}" \
      --query 'repository.externalConnections[0].externalConnectionName' \
      --output text)"
    if [[ "${live_conn}" == "${conn}" ]]; then
      echo "  Repository ${repo} upstream ${conn}: OK"
    else
      echo "  Repository ${repo} upstream: MISMATCH (live=${live_conn})" >&2
      exit 1
    fi
  done

  echo ""
  echo "==> CloudFormation stack ${STACK_NAME}"
  if aws_cmd cloudformation describe-stacks --stack-name "${STACK_NAME}" >/dev/null 2>&1; then
    aws_cmd cloudformation describe-stacks \
      --stack-name "${STACK_NAME}" \
      --query 'Stacks[0].{Name:StackName,Status:StackStatus}' \
      --output table
    echo "  Stack already exists — skip plan; run smoke or apply-tags if post-import."
  else
    local cf_err
    cf_err="$(aws_cmd cloudformation describe-stacks --stack-name "${STACK_NAME}" 2>&1 || true)"
    if echo "${cf_err}" | grep -q 'AccessDenied'; then
      echo "  Cannot describe stack (AccessDenied — Developer-Packages?). Assume SRE role for plan/execute."
    elif echo "${cf_err}" | grep -q 'does not exist'; then
      echo "  Stack not found — ready for IMPORT plan (requires SRE + CloudFormation)."
    else
      echo "  ${cf_err}" >&2
    fi
  fi

  if command -v cfn-lint >/dev/null 2>&1 || [[ -x "${ROOT}/.venv/bin/cfn-lint" ]]; then
    echo ""
    lint_and_validate_local_only
  fi
  echo ""
  echo "Preflight complete."
}

lint_and_validate_local_only() {
  if command -v cfn-lint >/dev/null 2>&1; then
    echo "==> cfn-lint ${TEMPLATE}"
    cfn-lint "${TEMPLATE}"
  elif [[ -x "${ROOT}/.venv/bin/cfn-lint" ]]; then
    echo "==> cfn-lint ${TEMPLATE} (via .venv)"
    "${ROOT}/.venv/bin/cfn-lint" "${TEMPLATE}"
  fi
}

lint_and_validate() {
  require_file "${TEMPLATE}"
  require_cloudformation
  if command -v cfn-lint >/dev/null 2>&1; then
    echo "==> cfn-lint ${TEMPLATE}"
    cfn-lint "${TEMPLATE}"
  elif [[ -x "${ROOT}/.venv/bin/cfn-lint" ]]; then
    echo "==> cfn-lint ${TEMPLATE} (via .venv)"
    "${ROOT}/.venv/bin/cfn-lint" "${TEMPLATE}"
  else
    echo "WARN: cfn-lint not found — skipping lint" >&2
  fi

  echo "==> aws cloudformation validate-template"
  aws_cmd cloudformation validate-template --template-body "file://${TEMPLATE}"
}

create_import_change_set() {
  require_cloudformation
  require_file "${TEMPLATE}"
  require_file "${PARAMS}"
  require_file "${IMPORT_RESOURCES}"

  if aws_cmd cloudformation describe-stacks --stack-name "${STACK_NAME}" >/dev/null 2>&1; then
    echo "Stack ${STACK_NAME} already exists." >&2
    echo "If resources are already imported, run: ./scripts/import-codeartifact-stack.sh smoke" >&2
    exit 1
  fi

  local change_set_name="${CHANGE_SET_PREFIX}-$(date +%Y%m%d%H%M%S)"
  echo "==> Creating IMPORT change set: ${change_set_name}"

  aws_cmd cloudformation create-change-set \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${change_set_name}" \
    --change-set-type IMPORT \
    --resources-to-import "file://${IMPORT_RESOURCES}" \
    --template-body "file://${TEMPLATE}" \
    --parameters "file://${PARAMS}" \
    --capabilities CAPABILITY_IAM \
    --tags \
      Key=Project,Value=MentorHub \
      Key=Environment,Value=shared-services \
      Key=ManagedBy,Value=CloudFormation

  echo ""
  echo "Waiting for change set to reach CREATE_COMPLETE (reviewable)..."
  aws_cmd cloudformation wait change-set-create-complete \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${change_set_name}"

  echo ""
  echo "Change set ready for review:"
  aws_cmd cloudformation describe-change-set \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${change_set_name}" \
    --query '{Status:Status,StatusReason:StatusReason,Changes:Changes[*].ResourceChange.{Action:Action,LogicalId:LogicalResourceId,Type:ResourceType}}' \
    --output table

  echo ""
  echo "Review the change set, then execute:"
  echo "  ./scripts/import-codeartifact-stack.sh execute ${change_set_name}"
}

execute_import_change_set() {
  require_cloudformation
  local change_set_name="${1:-}"
  if [[ -z "${change_set_name}" ]]; then
    change_set_name="$(aws_cmd cloudformation list-change-sets \
      --stack-name "${STACK_NAME}" \
      --query "sort_by(Summaries[?ChangeSetType=='IMPORT' && Status=='CREATE_COMPLETE'], &CreationTime)[-1].ChangeSetName" \
      --output text)"
    if [[ -z "${change_set_name}" || "${change_set_name}" == "None" ]]; then
      echo "No reviewable IMPORT change set found. Run: ./scripts/import-codeartifact-stack.sh plan" >&2
      exit 1
    fi
  fi

  echo "==> Executing change set: ${change_set_name}"
  aws_cmd cloudformation execute-change-set \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${change_set_name}"

  echo "Waiting for stack import to complete..."
  aws_cmd cloudformation wait stack-import-complete --stack-name "${STACK_NAME}"

  echo "Import complete."
  aws_cmd cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].{Name:StackName,Status:StackStatus,Outputs:Outputs}' \
    --output json
}

smoke_test() {
  echo "==> R020.6 list repositories in domain"
  aws_cmd codeartifact list-repositories-in-domain \
    --domain mentor-forge \
    --domain-owner 560167829275

  echo ""
  echo "==> Verify external connections"
  for repo in mentorhub-pypi mentorhub-npm; do
    echo "--- ${repo} ---"
    aws_cmd codeartifact describe-repository \
      --domain mentor-forge \
      --domain-owner 560167829275 \
      --repository "${repo}" \
      --query 'repository.{name:name,externalConnections:externalConnections[*].externalConnectionName}' \
      --output json
  done

  echo ""
  echo "Post-import consumer checks (manual):"
  echo "  R020.7 — mh / pipenv install / npm ci in a consumer repo"
  echo "  R020.8 — GitHub tag publish to CodeArtifact"
}

apply_resource_tags() {
  echo "==> R020.5 apply resource tags"
  local domain_arn pypi_arn npm_arn
  domain_arn="$(aws_cmd codeartifact describe-domain \
    --domain mentor-forge \
    --query 'domain.arn' \
    --output text)"
  pypi_arn="$(aws_cmd codeartifact describe-repository \
    --domain mentor-forge \
    --domain-owner 560167829275 \
    --repository mentorhub-pypi \
    --query 'repository.arn' \
    --output text)"
  npm_arn="$(aws_cmd codeartifact describe-repository \
    --domain mentor-forge \
    --domain-owner 560167829275 \
    --repository mentorhub-npm \
    --query 'repository.arn' \
    --output text)"

  for arn in "${domain_arn}" "${pypi_arn}" "${npm_arn}"; do
    echo "Tagging ${arn}"
    aws_cmd codeartifact tag-resource \
      --resource-arn "${arn}" \
      --tags \
        Key=Project,Value=mentorhub \
        Key=Environment,Value=shared-services \
        Key=ManagedBy,Value=CloudFormation
  done
  echo "Resource tags applied."
}

cmd="${1:-plan}"
case "${cmd}" in
  preflight)
    preflight_check
    ;;
  plan)
    lint_and_validate
    create_import_change_set
    ;;
  execute)
    execute_import_change_set "${2:-}"
    smoke_test
    ;;
  validate)
    lint_and_validate
    ;;
  smoke)
    smoke_test
    ;;
  apply-tags)
    apply_resource_tags
    ;;
  *)
    echo "Usage: $0 {preflight|plan|execute|validate|smoke|apply-tags}" >&2
    exit 1
    ;;
esac
