# R090 – Remaining Dev services

**Status**: Pending  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Deploy customer, mentor, and mentee journeys plus supporting ops services in Dev.

## Context / Input files

- [mentorhub/Specifications/ArchitectureDiagram.dev.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.svg)
- [mentorhub/Specifications/ArchitectureDiagram.dev.guide.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.guide.md)
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)

### Journeys

| Journey | API | SPA |
|---------|-----|-----|
| Customer | `customer_api` | `customer_spa` |
| Mentor | `mentor_api` | `mentor_spa` |
| Mentee | `mentee_api` | `mentee_spa` |

Also: `mongodb_api` (configure job), `runbook_api` (ops).

## Requirements

- [ ] **R090.1** ECR repos for each service image (or expand `templates/shared-services/ecr.yaml`)
- [ ] **R090.2** Template `templates/dev/ecs-services-customer.yaml` — deploy + smoke test
- [ ] **R090.3** Template `templates/dev/ecs-services-mentor.yaml` — deploy + smoke test
- [ ] **R090.4** Template `templates/dev/ecs-services-mentee.yaml` — deploy + smoke test *(merge [mentorhub_mentee_api](https://github.com/mentor-forge/mentorhub_mentee_api) CodeArtifact PR #1 first)*
- [ ] **R090.5** Wire API Gateway / ALB routes: SPA static + `/api/*` → paired API
- [ ] **R090.6** Replace interim dev `login.html` with Cognito when R070.2 complete
- [ ] **R090.7** Full Dev smoke test across all journeys

## Validation expectations

- Each journey smoke-tested independently and in combination.
- API routes correctly pair SPA and API services.

## Dependencies / Ordering

- **After:** `PENDING.R080.pilot_coordinator.md`

## Exit criteria

Full Development Environment swimlane in InfrastructureDiagram populated.

## Change control checklist

- [ ] ECR repos and ECS templates for all journeys.
- [ ] Per-journey smoke tests passed.
- [ ] Full Dev smoke test passed.
- [ ] Scoped commit referencing R090.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
