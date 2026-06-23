# R120 – Staging environment

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Copy Dev templates to a staging account with smaller sizing and immutable image promotion.

## Context / Input files

- [mentorhub/Specifications/CloudEnvironmentPlan.md](../docs/specifications/CloudEnvironmentPlan.md) — §Phase 2 account model
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)
- [mentorhub/Specifications/InfrastructureDiagram.svg](../docs/specifications/InfrastructureDiagram.svg)

## Requirements

- [ ] **R120.1** Decide account model (CloudEnvironmentPlan §Phase 2)
- [ ] **R120.2** Add `parameters/staging.json`
- [ ] **R120.3** Deploy R040–R090 stack set in staging account (smaller sizing)
- [ ] **R120.4** CD: promote immutable image dev → staging
- [ ] **R120.5** Create `ArchitectureDiagram.staging.svg` in mentorhub Specifications
- [ ] **R120.6** Staging smoke test + test-data policy

## Validation expectations

- Staging stacks deploy from same templates with environment-specific parameters.
- Image promotion uses sha/semver tags, not mutable `latest`.

## Dependencies / Ordering

- **After:** `PENDING.R110.documentation_hygiene.md`

## Exit criteria

Second swimlane in InfrastructureDiagram live.

## Change control checklist

- [ ] Staging account and parameters documented.
- [ ] Full stack set deployed.
- [ ] Smoke test and promotion path verified.
- [ ] Scoped commit referencing R120.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
