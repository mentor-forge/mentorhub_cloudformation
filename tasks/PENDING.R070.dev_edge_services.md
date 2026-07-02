# R070 – Dev: edge and supporting services

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy API Gateway, Cognito, S3, Route53/ACM, and SES stacks for Dev — defer individual stacks if blocked by domain or IdP decisions.

## Context / Input files

- [README.md](../README.md) — platform overview
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)
- [ArchitectureDiagram.dev.svg](../docs/ArchitectureDiagram.dev.svg)
- [mentorhub/DeveloperEdition/standards/sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md)

## Requirements

- [ ] **R070.1** Template `templates/dev/api-gateway.yaml` — HTTP/REST API, route to pilot API
- [ ] **R070.2** Template `templates/dev/cognito.yaml` — user pool + app clients *(or defer: interim welcome JWT)*
- [ ] **R070.3** Template `templates/dev/s3.yaml` — app bucket(s), block public access
- [ ] **R070.4** Template `templates/dev/route53-acm.yaml` — hosted zone + ACM cert *(when domain owned)*
- [ ] **R070.5** Template `templates/dev/ses.yaml` — verified domain / sandbox *(when email ready)*
- [ ] **R070.6** Validate: API Gateway URL returns coordinator API health (HTTPS optional until R070.4)

## Validation expectations

- API Gateway integrates with network/ECS outputs.
- Deferred stacks documented as `Blocked` follow-up tasks if prerequisites missing.

## Dependencies / Ordering

- **After:** `PENDING.R060.dev_compute_platform.md`
- **Before:** `PENDING.R080.pilot_coordinator.md`

## Exit criteria

Dev swimlane edge services deployed as far as decisions allow; API Gateway reachable for pilot.

## Change control checklist

- [ ] Each template linted and validated.
- [ ] Deployed stacks smoke-tested.
- [ ] Deferred items noted with rationale.
- [ ] Scoped commit referencing R070.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
