# R070 – Dev: edge and supporting services

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy **ALB** (public HTTPS edge), Cognito, S3, Route53/ACM, and SES stacks for Dev — defer individual stacks if blocked by domain or IdP decisions.

**Edge decision:** [ARCHITECTURE.md](../ARCHITECTURE.md) — **ALB**, not API Gateway (ECS + path routing + in-app JWT validation).

## Context / Input files

- [README.md](../README.md) — platform overview
- [ARCHITECTURE.md](../ARCHITECTURE.md) — network and edge (ALB decision)
- [ArchitectureDiagram.dev.svg](../docs/ArchitectureDiagram.dev.svg)
- [mentorhub/DeveloperEdition/standards/sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md)

## Requirements

- [ ] **R070.1** Template `templates/dev/alb.yaml` — internet-facing ALB, HTTPS listener (ACM), listener rules for pilot paths, target group outputs for R080
- [ ] **R070.2** Template `templates/dev/cognito.yaml` — user pool + app clients *(or defer: interim welcome JWT)*
- [ ] **R070.3** Template `templates/dev/s3.yaml` — app bucket(s), block public access
- [ ] **R070.4** Template `templates/dev/route53-acm.yaml` — hosted zone + ACM cert *(when domain owned)*
- [ ] **R070.5** Template `templates/dev/ses.yaml` — verified domain / sandbox *(when email ready)*
- [ ] **R070.6** Validate: ALB URL returns coordinator API health (HTTP until R070.4; HTTPS after ACM on listener)

## Validation expectations

- ALB integrates with network/ECS outputs (target groups registered from R080).
- Deferred stacks documented as `Blocked` follow-up tasks if prerequisites missing.

## Dependencies / Ordering

- **After:** `PENDING.R060.dev_compute_platform.md`
- **Before:** `PENDING.R080.pilot_coordinator.md`

## Exit criteria

Dev swimlane edge services deployed as far as decisions allow; **ALB** reachable for pilot.

## Change control checklist

- [ ] Each template linted and validated.
- [ ] Deployed stacks smoke-tested.
- [ ] Deferred items noted with rationale.
- [ ] Scoped commit referencing R070.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**

- Update `ArchitectureDiagram.dev.*` labels from API Gateway to ALB (R110).
