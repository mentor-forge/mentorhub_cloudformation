# R060 – Dev: ECS compute platform

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy Fargate ECS cluster, CloudWatch log groups, and task execution role (ECR pull, Secrets Manager, logs).

## Context / Input files

- [README.md](../README.md) — platform overview
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)
- Network stack outputs from R040

## Requirements

- [ ] **R060.1** Template `templates/dev/ecs-cluster.yaml` — Fargate cluster + CloudWatch log groups
- [ ] **R060.2** ECS task execution role: ECR pull (cross-account or pull-through local namespace), Secrets Manager read, CloudWatch logs
- [ ] **R060.2a** Optional stack `templates/dev/ecr-pull-through.yaml` — pull-through cache rule from Shared-Services ([docs/ecr-cross-account.md](../docs/ecr-cross-account.md))
- [ ] **R060.3** Validate: empty cluster visible in console

Log forwarding to Shared-Services OpenSearch is defined in [R031](./PENDING.R031.shared_services_cloudtrail_budget.md) (R031.8–R031.9); wire forwarding when ECS services deploy (R080+).

## Validation expectations

- Cluster and IAM roles deploy without service definitions.
- Execution role policy allows ECR (shared-services account) and secrets from R050.

## Dependencies / Ordering

- **After:** `PENDING.R040.dev_governance_network.md`
- **Before:** `PENDING.R070.dev_edge_services.md`, `PENDING.R080.pilot_coordinator.md`

## Exit criteria

Empty ECS cluster ready for service stacks.

## Change control checklist

- [ ] Cluster and roles deployed.
- [ ] Console verification complete.
- [ ] Scoped commit referencing R060.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
