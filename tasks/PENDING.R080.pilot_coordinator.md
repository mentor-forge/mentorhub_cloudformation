# R080 – Pilot application (coordinator)

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy coordinator API, SPA, and optional welcome service to ECS — first end-to-end cloud Dev journey.

## Context / Input files

- [README.md](../README.md) — platform overview
- [mentorhub/DeveloperEdition/docker-compose.yaml](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/docker-compose.yaml) — local ports: API `8389`, SPA `8390`, welcome `8080`
- [ArchitectureDiagram.dev.svg](../docs/ArchitectureDiagram.dev.svg)

## Requirements

- [ ] **R080.1** Template `templates/dev/ecs-services-coordinator.yaml`
- [ ] **R080.2** Task definition: `coordinator_api` (image from ECR or interim GHCR)
- [ ] **R080.3** Task definition: `coordinator_spa` (env: `API_HOST`, `IDP_LOGIN_URI`, JWT settings)
- [ ] **R080.4** Task definition: `welcome` (optional for interim dev login)
- [ ] **R080.5** ECS services in private subnets; register with **ALB** target groups (R070)
- [ ] **R080.6** Env vars from Secrets Manager — not baked into images
- [ ] **R080.7** Run `mongodb_api` configure job once against DocumentDB (ops runbook)
- [ ] **R080.8** Smoke test: login → coordinator SPA → API round-trip → data in DocumentDB
- [ ] **R080.9** Document rollback: previous task definition / image tag

## Validation expectations

- Full coordinator journey works in cloud Dev.
- Secrets injected at runtime; no credentials in images.

## Dependencies / Ordering

- **After:** `PENDING.R050.dev_data_secrets.md`, `PENDING.R060.dev_compute_platform.md`, `PENDING.R070.dev_edge_services.md`

## Exit criteria

First journey live in cloud Dev; matches pilot scope in CloudEnvironmentPlan.md.

## Change control checklist

- [ ] ECS services deployed and healthy.
- [ ] Smoke test documented with results.
- [ ] Rollback runbook noted.
- [ ] Scoped commit referencing R080.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
