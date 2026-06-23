# R110 – Documentation and diagram hygiene

**Status**: Pending  
**Task Type**: Docs  
**Run Mode**: Sequential

## Goal

Align specifications, diagrams, and SRE standards with deployed infrastructure.

## Context / Input files

- [mentorhub/Specifications/ArchitectureDiagram.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.md)
- [mentorhub/Specifications/InfrastructureDiagram.svg](../docs/specifications/InfrastructureDiagram.svg)
- [mentorhub/DeveloperEdition/standards/sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md)
- [mentorhub/Specifications/CloudEnvironmentPlan.md](../docs/specifications/CloudEnvironmentPlan.md)

## Requirements

- [ ] **R110.1** Update ArchitectureDiagram.md — link Infrastructure + CF checklist + mentorhub_cloudformation repo
- [ ] **R110.2** Update InfrastructureDiagram.svg — add missing internal arrows (VPC ↔ ECS ↔ API Gateway ↔ DocumentDB)
- [ ] **R110.3** Note GHCR interim vs ECR target on diagram
- [ ] **R110.4** Revise sre_standards.md to as-implemented (replace "IaC TBD")
- [ ] **R110.5** Update CloudEnvironmentPlan.md checkboxes to match deployed stacks
- [ ] **R110.6** Runbook in mentorhub_cloudformation: deploy, rollback, destroy Dev stack, monthly cost check

## Validation expectations

- New SRE can follow checklist + tasks without tribal knowledge.
- Diagram reflects as-built state.

## Dependencies / Ordering

- **After:** `PENDING.R090.remaining_dev_services.md`, `PENDING.R100.cicd_ecs_deploy.md`

## Exit criteria

Specs match reality; documentation sufficient for onboarding.

## Change control checklist

- [ ] mentorhub spec PR with diagram and standards updates.
- [ ] Runbook added to mentorhub_cloudformation.
- [ ] Scoped commits referencing R110.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
