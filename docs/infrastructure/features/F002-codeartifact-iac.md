# F002 — CodeArtifact under CloudFormation

**Status:** In progress  
**Tasks:** [R020](../../../tasks/RUNNING.R020.codeartifact_import.md), [R031](../../../tasks/PENDING.R031.shared_services_cloudtrail_budget.md)

## Goal

Existing CodeArtifact domain and repos are managed by CloudFormation (import, not recreate). Shared-Services governance codified.

## Deliverables

- [x] Import template + script (R020 — merged)
- [ ] Execute import in AWS (SRE)
- [ ] CloudTrail + budget + OIDC in CF (R031)

## Done when

CodeArtifact under CF with zero consumer breakage; Shared-Services audit trail active.

## Note

CodeArtifact is **build-time only** — separate from the container image pipeline (F001).
