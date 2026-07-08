# R031 – Shared-Services: CloudTrail, budget, and OIDC hygiene

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Codify Shared-Services governance (CloudTrail, budget alarm) and import or reference existing GitHub OIDC roles for CodeArtifact that were created manually during initial platform setup. Deploy Shared-Services log analytics foundation (OpenSearch domain and CloudWatch → OpenSearch pipeline design).

Runs after [R030](./RUNNING.R030.ecr_ghcr_connection.md) ships.

## Context / Input files

- [README.md](../README.md)
- [config/aws-platform.yaml](../config/aws-platform.yaml)
- [ARCHITECTURE.md](../ARCHITECTURE.md) — observability (F15, F16)

## Requirements

### CodeArtifact OIDC (import if manual)

- [ ] **R031.1** Template `templates/shared-services/github-oidc-codeartifact.yaml` (or consolidate with existing OIDC template)
- [ ] **R031.2** Role `GitHubActionsCodeArtifactPublish` (import if manual)
- [ ] **R031.3** Role `GitHubActionsCodeArtifactRead` (import if manual — §0.2.3)
- [ ] **R031.4** Validate: test workflow `aws sts get-caller-identity` per role

### CloudTrail and budget

- [ ] **R031.5** Template `templates/shared-services/cloudtrail.yaml` + budget alarm (~$25/month)
- [ ] **R031.6** Validate: trail logging; budget notification received

### Log pipeline (CloudWatch → OpenSearch)

Shared-Services hosts Amazon OpenSearch Service; workload accounts forward ECS and ALB logs. See [ARCHITECTURE.md](../ARCHITECTURE.md) observability (F15, F16).

- [ ] **R031.7** Template `templates/shared-services/opensearch.yaml` — OpenSearch domain + Dashboards access; size for dev volume with scale-up path (F15)
- [ ] **R031.8** Design and document log pipeline: Fluent Bit sidecar vs CloudWatch Logs subscription → OpenSearch Ingestion / direct indexing; index prefixes or ISM policies per environment/tenant (F16)
- [ ] **R031.9** Dev workload forwarding — template or documented pattern for mentorhub-dev (CloudWatch Logs → Shared-Services OpenSearch); enrich with `tenant`, `environment`, `service`, `journey` log fields; coordinate with [R060](./PENDING.R060.dev_compute_platform.md) log groups
- [ ] **R031.10** Validate: sample log line from mentorhub-dev searchable in OpenSearch Dashboards

## Validation expectations

- Lint and validate-template for each new template.
- OIDC role assumption from a test GitHub Actions workflow (if roles imported).
- CloudTrail active; budget alarm configured.

## Dependencies / Ordering

- **After:** [RUNNING.R030.ecr_ghcr_connection.md](./RUNNING.R030.ecr_ghcr_connection.md)

## Exit criteria

Shared-Services CloudTrail and budget are under CloudFormation; CodeArtifact OIDC roles are codified or documented as imported; OpenSearch domain and log pipeline design are in templates or documented for dev workload forwarding.

## Change control checklist

- [ ] Reviewed `config/aws-platform.yaml`.
- [ ] Templates linted and validated.
- [ ] CloudTrail and budget smoke tests passed.
- [ ] Scoped commit referencing R031.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
