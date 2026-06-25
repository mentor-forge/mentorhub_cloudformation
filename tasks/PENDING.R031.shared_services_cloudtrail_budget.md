# R031 – Shared-Services: CloudTrail, budget, and OIDC hygiene

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Codify Shared-Services governance (CloudTrail, budget alarm) and import or reference existing GitHub OIDC roles for CodeArtifact that were created manually during DEPENDENCY_MOVE Phase 0.

This task is **Next** on the [Cloud Dev Roadmap](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/CloudDevRoadmap.md) after [R030](./RUNNING.R030.ecr_ghcr_connection.md) ships.

## Context / Input files

- [mentorhub/Specifications/CloudDevRoadmap.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/CloudDevRoadmap.md)
- [docs/specifications/DEPENDENCY_MOVE.md](../docs/specifications/DEPENDENCY_MOVE.md) — OIDC roles §0.2.2, §0.2.3
- [docs/specifications/aws-platform.yaml](../docs/specifications/aws-platform.yaml)
- [docs/specifications/INFO.md](../docs/specifications/INFO.md)

## Requirements

### CodeArtifact OIDC (import if manual)

- [ ] **R031.1** Template `templates/shared-services/github-oidc-codeartifact.yaml` (or consolidate with existing OIDC template)
- [ ] **R031.2** Role `GitHubActionsCodeArtifactPublish` (import if manual — DEPENDENCY_MOVE §0.2.2)
- [ ] **R031.3** Role `GitHubActionsCodeArtifactRead` (import if manual — §0.2.3)
- [ ] **R031.4** Validate: test workflow `aws sts get-caller-identity` per role

### CloudTrail and budget

- [ ] **R031.5** Template `templates/shared-services/cloudtrail.yaml` + budget alarm (~$25/month)
- [ ] **R031.6** Validate: trail logging; budget notification received

## Validation expectations

- Lint and validate-template for each new template.
- OIDC role assumption from a test GitHub Actions workflow (if roles imported).
- CloudTrail active; budget alarm configured.

## Dependencies / Ordering

- **After:** [RUNNING.R030.ecr_ghcr_connection.md](./RUNNING.R030.ecr_ghcr_connection.md)

## Exit criteria

Shared-Services CloudTrail and budget are under CloudFormation; CodeArtifact OIDC roles are codified or documented as imported.

## Change control checklist

- [ ] Reviewed DEPENDENCY_MOVE.md OIDC sections.
- [ ] Templates linted and validated.
- [ ] CloudTrail and budget smoke tests passed.
- [ ] Scoped commit referencing R031.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
