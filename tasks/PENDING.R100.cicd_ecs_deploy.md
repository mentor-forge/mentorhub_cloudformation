# R100 – CI/CD: ECR and ECS deploy

**Status**: Pending  
**Task Type**: CI  
**Run Mode**: Sequential

## Goal

Close InfrastructureDiagram CI/CD arrows: git → GitHub Actions → ECR → ECS, with CodeArtifact packages unchanged.

## Context / Input files

- [config/aws-platform.yaml](../config/aws-platform.yaml)
- [InfrastructureDiagram.svg](../docs/InfrastructureDiagram.svg)
- Service repos: `mentorhub_coordinator_api`, `mentorhub_coordinator_spa`, etc.

```text
git → GitHub Actions → ECR → ECS (MentorHub-Dev)
              ↓
        CodeArtifact (packages — already live)
```

## Requirements

- [ ] **R100.1** Roll dual-push `docker-push.yml` (pattern from R030) to pilot repos (`mentorhub_coordinator_api`, `mentorhub_coordinator_spa`): push to ECR
- [ ] **R100.2** Add deploy step: update ECS service on merge to `main` (OIDC `GitHubActionsECSDeploy`)
- [ ] **R100.3** Keep GHCR push in parallel until ECR path proven; then evaluate GHCR retirement
- [ ] **R100.4** Roll CI pattern to customer, mentor, mentee, welcome repos
- [ ] **R100.5** Validate: merge trivial change → new image running in ECS within expected time
- [ ] **R100.6** Document promotion: immutable tag discipline (`latest` dev only; semver or sha for staging+)

**Note:** Workflow changes land in **service repos**, not this repo. This task tracks coordination and validation.

## Validation expectations

- OIDC roles from R030 used successfully in service repo workflows.
- End-to-end deploy without manual console steps.

## Dependencies / Ordering

- **After:** `PENDING.R030.shared_services_oidc_ecr.md`, `PENDING.R080.pilot_coordinator.md`

## Exit criteria

Diagram CI/CD arrows implemented; Dev deploys from git without manual console steps.

## Change control checklist

- [ ] Pilot service workflows updated and green.
- [ ] ECS deploy verified after merge.
- [ ] Pattern documented for remaining repos.
- [ ] Scoped commits in each affected repo referencing R100.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
