# Planning roadmap — platform infrastructure (draft)

**Status:** Draft for review · **Branch:** `Planning`  
**Canonical intent file:** [infrastructure.yaml](./infrastructure.yaml)

This folder is the **planning roadmap** for MentorHub AWS platform architecture. It separates **infrastructure intent** from **product architecture** ([mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)) and **executable work** ([tasks/](../../tasks/README.md)).

---

## Vocabulary

| Level | Definition | Artifact |
|-------|------------|----------|
| **Task** | Smallest unit of work; documented in the task automation framework | `tasks/PENDING\|RUNNING\|SHIPPED.R*.md` |
| **Feature** | Shippable platform capability; may package one or more container images + IaC | `features/F*.md` |
| **Release** | Immutable set of image digests + config promoted together | Tagged digest set (semver or env prefix) |
| **Deploy** | Promotion of a release to a runtime environment or tenant | ECS task update, automation workflow |

**Change control flow:**

```text
Task (commit) → Feature (merge + package) → Release (tagged digest) → Deploy (change control)
```

---

## Document index

### Core

| Document | Purpose |
|----------|---------|
| [infrastructure.yaml](./infrastructure.yaml) | Platform intent: accounts, services, tenants, features, decisions |
| [principles.md](./principles.md) | Architectural principles (immutability, promotion, tenancy) |
| [accounts.md](./accounts.md) | AWS organization and account layout |

### Environments

| Document | Purpose |
|----------|---------|
| [environments/local.md](./environments/local.md) | Developer Edition / Docker Compose |
| [environments/dev-multi-tenant.md](./environments/dev-multi-tenant.md) | DEV / TEST / TRAINING on shared DocumentDB |
| [environments/staging.md](./environments/staging.md) | Prod mirror; spin-down between releases |
| [environments/production.md](./environments/production.md) | Single-tenant live environment |

### Services (AWS mapping)

| Document | Purpose |
|----------|---------|
| [services/networking.md](./services/networking.md) | VPC, NAT, security groups |
| [services/edge.md](./services/edge.md) | API Gateway, Route 53, ACM, CloudFront |
| [services/compute.md](./services/compute.md) | ECS Fargate, task definitions |
| [services/data.md](./services/data.md) | DocumentDB, tenant databases |
| [services/identity.md](./services/identity.md) | Cognito, JWT, interim welcome page |
| [services/messaging.md](./services/messaging.md) | SES; MailHog local mapping |
| [services/integrations.md](./services/integrations.md) | Stripe, webhooks |
| [services/registry.md](./services/registry.md) | GHCR, ECR, CodeArtifact |
| [services/observability.md](./services/observability.md) | CloudWatch, CloudTrail |

### Feature plans (high level)

| ID | Feature | Status | Tasks |
|----|---------|--------|-------|
| F001 | [Image pipeline (GHCR ↔ ECR)](./features/F001-image-pipeline.md) | Now | R030 |
| F002 | [CodeArtifact under CloudFormation](./features/F002-codeartifact-iac.md) | In progress | R020, R031 |
| F003 | [Dev platform (network, data, compute)](./features/F003-dev-platform.md) | Planned | R040–R060 |
| F004 | [Edge routing and authentication](./features/F004-edge-and-auth.md) | Planned | R070 |
| F005 | [Coordinator pilot in cloud](./features/F005-coordinator-pilot.md) | Planned | R080 |
| F006 | [Full Dev + CI/CD deploy](./features/F006-full-dev-deploy.md) | Planned | R090, R100, R110 |
| F007 | [Staging lifecycle](./features/F007-staging-lifecycle.md) | Later | R120 |
| F008 | [Production](./features/F008-production.md) | Later | R130 |

---

## Related documents

| Document | Location |
|----------|----------|
| Now / Next / Later rhythm | [CloudDevRoadmap.md](../specifications/CloudDevRoadmap.md) |
| Integrated critical path | [LiveDevPlan.md](../specifications/LiveDevPlan.md) |
| IaC task index | [CLOUDFORMATION_CHECKLIST.md](../specifications/CLOUDFORMATION_CHECKLIST.md) |
| CloudFormation milestones | [CLOUDFORMATION_PLAN.md](../specifications/CLOUDFORMATION_PLAN.md) |
| Platform runtime scope | [CloudEnvironmentPlan.md](../specifications/CloudEnvironmentPlan.md) |
| Dev diagram finish guide | [ArchitectureDiagram.dev.guide.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.guide.md) |

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-25 | Initial planning roadmap draft on `Planning` branch |
