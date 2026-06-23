# R130 – Production environment

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy production account with HA, backups, production IdP, and sign-off checklist.

## Context / Input files

- [mentorhub/Specifications/CloudEnvironmentPlan.md](../docs/specifications/CloudEnvironmentPlan.md)
- [mentorhub/DeveloperEdition/standards/sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md)
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)

## Requirements

- [ ] **R130.1** Production account + stricter IAM
- [ ] **R130.2** Add `parameters/production.json`
- [ ] **R130.3** HA DocumentDB, backups, multi-AZ where required
- [ ] **R130.4** Production Cognito / IdP per sre_standards.md
- [ ] **R130.5** Route53 production domain + ACM
- [ ] **R130.6** Stripe live mode cutover (customer_api)
- [ ] **R130.7** Production checklist sign-off
- [ ] **R130.8** Create `ArchitectureDiagram.production.svg` in mentorhub Specifications

## Validation expectations

- Production change control stricter than Dev/Staging (approvals, maintenance windows).
- Sign-off checklist completed and archived.

## Dependencies / Ordering

- **After:** `PENDING.R120.staging.md`

## Exit criteria

Third swimlane in InfrastructureDiagram live.

## Change control checklist

- [ ] Production parameters and account documented.
- [ ] HA and backup requirements met.
- [ ] Sign-off checklist completed.
- [ ] Scoped commit referencing R130.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
