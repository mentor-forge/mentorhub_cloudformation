# F006 — Full Dev + CI/CD deploy

**Status:** Planned  
**Tasks:** R090, R100, R110

## Goal

All journeys run in MentorHub-Dev; merge to `main` deploys to ECS without manual console steps; docs match reality.

## Deliverables

| Task | Scope |
|------|-------|
| R090 | All journey ECS services (customer, mentor, mentee, coordinator) |
| R100 | CI/CD: ECR digest → ECS deploy automation; tenant/tag promotion |
| R110 | Diagrams, sre_standards, runbooks aligned with deployed Dev |

## Deploy automation target

```text
deploy --tenant dev --digest sha256:... --journeys all
deploy --tenant test --tag test
```

## Done when

- All four journeys smoke-tested in Dev
- No manual ECS console deploy for routine updates
- ArchitectureDiagram.dev.svg reflects deployed state

## Depends on

- F005 (pilot proven)

## Unblocks

F007 (staging), multi-tenant test/training workflows
