# R040 – Dev: governance and network

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy MentorHub-Dev foundation: account ID recorded, CloudTrail/budget, VPC, subnets, NAT, and security groups.

## Context / Input files

- [mentorhub/Specifications/aws-platform.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/aws-platform.yaml)
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)
- [mentorhub/Specifications/InfrastructureDiagram.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/InfrastructureDiagram.svg)
- `parameters/dev.json` in this repo

## Requirements

- [ ] **R040.1** Record MentorHub-Dev AWS account ID in `parameters/dev.json` and aws-platform.yaml (mentorhub PR)
- [ ] **R040.2** Template `templates/dev/cloudtrail.yaml` + budget (~$50/month)
- [ ] **R040.3** Template `templates/dev/network.yaml` — VPC `10.0.0.0/16`, 2 public + 2 private subnets, IGW, NAT
- [ ] **R040.4** Security groups: `alb-sg`, `ecs-sg`, `documentdb-sg` (gateway → ECS → DB)
- [ ] **R040.5** Validate: subnets and NAT; private egress works

Deploy **in order**: cloudtrail → network (network exports VPC/subnet IDs for later stacks).

## Validation expectations

- Lint and validate-template for each template.
- Deploy with `--profile mentorhub-dev`.
- Private subnet egress test (e.g., NAT gateway route, optional SSM test instance).

## Dependencies / Ordering

- **After:** `PENDING.R030.shared_services_oidc_ecr.md`

## Exit criteria

Dev VPC and governance stacks deployed; network outputs available for Phase 3B–3D tasks.

## Change control checklist

- [ ] Dev account ID recorded in parameters and aws-platform.yaml.
- [ ] Stacks deployed in order.
- [ ] Network smoke test passed.
- [ ] Scoped commit referencing R040.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
