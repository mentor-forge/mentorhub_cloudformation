# R030 – Shared-Services: ECR provisioning and GHCR connection

**Status**: Running  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Provision ECR repositories in Shared-Services and connect them to the existing GHCR publish path so merge to `main` pushes the **same image** to both registries.

## Context / Input files

- [README.md](../README.md) — platform overview
- [config/aws-platform.yaml](../config/aws-platform.yaml)
- [InfrastructureDiagram.svg](../docs/InfrastructureDiagram.svg)
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)
- [mentorhub/DeveloperEdition/standards/sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md) — CI publish model
- [mentorhub/DeveloperEdition/standards/examples/docker-push-codeartifact.yml](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/examples/docker-push-codeartifact.yml) — canonical workflow pattern

## Requirements

### GitHub OIDC (ECR push only)

- [ ] **R030.1** Template `templates/shared-services/github-oidc-ecr.yaml` (or extend a minimal OIDC template) with OIDC provider `token.actions.githubusercontent.com` (skip/create if exists)
- [ ] **R030.2** Role `GitHubActionsECRPush` — trust scoped to `mentor-forge` repos; ECR push permissions for pilot repos
- [ ] **R030.3** Store role ARN in GitHub org secret (e.g. `AWS_ROLE_ARN_ECR_PUSH`) and document in `aws-platform.yaml`

### ECR

- [ ] **R030.4** Template `templates/shared-services/ecr.yaml` — replace placeholder
- [ ] **R030.5** ECR repos (pilot): `mentorhub-welcome`, `mentorhub-coordinator-api`, `mentorhub-coordinator-spa`
- [ ] **R030.6** ECR lifecycle policy (retain last N images per repo)
- [ ] **R030.6a** Repository policies on pilot repos — allow workload account ECS execution roles to pull ([docs/ecr-cross-account.md](../docs/ecr-cross-account.md))

### GHCR connection (dual push)

- [ ] **R030.7** Update pilot `docker-push.yml` in one repo (recommend `mentorhub` welcome or `mentorhub_coordinator_api`): after GHCR login, also log in to ECR via OIDC and push the same tags to both registries
- [ ] **R030.8** Document dual-push pattern in `sre_standards.md` for R100 rollout

## Out of scope (deferred)

| Item | Task |
|------|------|
| Shared-Services CloudTrail + budget | [PENDING.R031.shared_services_cloudtrail_budget.md](./PENDING.R031.shared_services_cloudtrail_budget.md) |
| Import/codify CodeArtifact OIDC roles | R031 |
| `GitHubActionsECSDeploy` role | R100 |
| ECS deploy on merge | R100 |
| GHCR removal + Developer Edition ECR pull | [PENDING.R100.cicd_ecs_deploy.md](./PENDING.R100.cicd_ecs_deploy.md) (R100.3, R100.7) |

## Validation expectations

- `cfn-lint` on new/changed templates
- `aws cloudformation validate-template` with `--profile mentorhub-shared` and `--region us-east-1`
- Deploy ECR + OIDC stacks to Shared-Services
- Test workflow: `aws sts get-caller-identity` assuming `GitHubActionsECRPush`
- Merge (or workflow_dispatch) produces image in **both** GHCR and ECR for pilot repo

## Dependencies / Ordering

- **After:** [RUNNING.R020.codeartifact_import.md](./RUNNING.R020.codeartifact_import.md) (template merged; import execute may run in parallel)
- **Blocks:** R060 (ECS ECR pull), R080 (pilot images in ECR)

## Exit criteria

Pilot ECR repos exist; merge to `main` on one service repo pushes `:latest` to GHCR and ECR via OIDC.

## Change control checklist

- [ ] Reviewed README.md and config/aws-platform.yaml.
- [ ] Templates linted and validated.
- [ ] OIDC and dual-push smoke tests passed.
- [ ] Scoped commit referencing R030.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**

- Roll dual-push to remaining repos in R100.
