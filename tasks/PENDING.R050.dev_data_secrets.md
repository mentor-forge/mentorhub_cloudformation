# R050 – Dev: data and secrets

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy DocumentDB and Secrets Manager entries for database connection strings and JWT secrets.

## Context / Input files

- [mentorhub/Specifications/CloudEnvironmentPlan.md](../docs/specifications/CloudEnvironmentPlan.md)
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)
- [mentorhub/Specifications/InfrastructureDiagram.svg](../docs/specifications/InfrastructureDiagram.svg)
- Network stack outputs from R040

## Requirements

- [ ] **R050.1** Template `templates/dev/documentdb.yaml` — cluster (dev sizing), subnet group in private subnets
- [ ] **R050.2** Template `templates/dev/secrets.yaml` — Secrets Manager: DocumentDB connection string, `JWT_SECRET`
- [ ] **R050.3** Validate: connection from a one-off task or bastion

## Validation expectations

- DocumentDB in private subnets; security group allows ECS SG only.
- Secrets readable by ECS task execution role (verify in R060 or here with test role).

## Dependencies / Ordering

- **After:** `PENDING.R040.dev_governance_network.md`
- **Before:** `PENDING.R080.pilot_coordinator.md`

## Exit criteria

DocumentDB cluster live; secrets populated and connectivity verified.

## Change control checklist

- [ ] Templates reference network stack exports.
- [ ] Connection smoke test documented.
- [ ] Scoped commit referencing R050.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
