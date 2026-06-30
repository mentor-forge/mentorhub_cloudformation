# F001 — Image pipeline (GHCR ↔ ECR)

**Status:** Now  
**Tasks:** [R030](../../../tasks/RUNNING.R030.ecr_ghcr_connection.md)

## Goal

ECR repositories in Shared-Services receive the **same immutable digest** as GHCR on every merge to `main`. AWS runtimes can pull images without a separate build.

## Why now

CI already publishes to GHCR. Nothing in AWS can run containers until ECR exists and dual-push is wired.

## Deliverables

- [ ] `GitHubActionsECRPush` OIDC role
- [ ] ECR repos + lifecycle policies (pilot set)
- [ ] Dual-push GHCR + ECR on merge (pilot repo, then all journey repos)

## Done when

Merge to `main` on pilot repo produces matching `:latest` in GHCR and ECR (same digest).

## Depends on

- Shared-Services account ✓
- CodeArtifact for build deps ✓

## Unblocks

All Dev deploy work (F003–F006).
