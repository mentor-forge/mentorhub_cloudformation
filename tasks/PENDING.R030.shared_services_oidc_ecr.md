# R030 – Shared-Services: CI identity, ECR, and CloudTrail

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Codify GitHub OIDC roles, ECR repositories, and Shared-Services CloudTrail/budget in CloudFormation.

## Context / Input files

- [mentorhub/Specifications/DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/DEPENDENCY_MOVE.md) — OIDC roles §0.2.2, §0.2.3
- [mentorhub/Specifications/aws-platform.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/aws-platform.yaml)
- [mentorhub/Specifications/InfrastructureDiagram.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/InfrastructureDiagram.svg)
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)

## Requirements

### GitHub OIDC

- [ ] **R030.1** Template `templates/shared-services/github-oidc.yaml`
- [ ] **R030.2** OIDC provider `token.actions.githubusercontent.com` (skip if exists; import or reference)
- [ ] **R030.3** Role `GitHubActionsCodeArtifactPublish` (import if manual — DEPENDENCY_MOVE §0.2.2)
- [ ] **R030.4** Role `GitHubActionsCodeArtifactRead` (import if manual — §0.2.3)
- [ ] **R030.5** Role `GitHubActionsECRPush` (new)
- [ ] **R030.6** Role `GitHubActionsECSDeploy` (new; trust scoped to `mentor-forge` repos)
- [ ] **R030.7** Store role ARNs in GitHub org secrets / aws-platform.yaml as needed
- [ ] **R030.8** Validate: test workflow `aws sts get-caller-identity` per role

### ECR

- [ ] **R030.9** Template `templates/shared-services/ecr.yaml`
- [ ] **R030.10** ECR repos (pilot): `mentorhub-welcome`, `mentorhub-coordinator-api`, `mentorhub-coordinator-spa`
- [ ] **R030.11** ECR lifecycle policy (retain last N images)
- [ ] **R030.12** Validate: CI push one image to ECR via OIDC

### CloudTrail and budget

- [ ] **R030.13** Template `templates/shared-services/cloudtrail.yaml` + budget alarm (~$25/month)
- [ ] **R030.14** Validate: trail logging; budget notification received

## Validation expectations

- Lint and validate-template for each new template.
- OIDC role assumption from a test GitHub Actions workflow.
- At least one image pushed to ECR via OIDC.

## Dependencies / Ordering

- **After:** `PENDING.R020.codeartifact_import.md`

## Exit criteria

Shared-Services platform boxes in InfrastructureDiagram (except CloudFormation meta) are live and codified.

## Change control checklist

- [ ] Reviewed DEPENDENCY_MOVE.md OIDC sections.
- [ ] Templates linted and validated.
- [ ] OIDC and ECR smoke tests passed.
- [ ] Scoped commit referencing R030.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
