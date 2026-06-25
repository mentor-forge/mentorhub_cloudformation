# MentorHub SRE documentation

Platform infrastructure specifications, migration runbooks, and as-built records for SRE work. **Executable tasks** live in [`../tasks/`](../tasks/); **templates** in [`../templates/`](../templates/).

## Specifications (`specifications/`)

| Document | Purpose |
|----------|---------|
| [roadmap.yaml](./specifications/roadmap.yaml) | Product + platform roadmap (YAML) |
| [CloudDevRoadmap.md](./specifications/CloudDevRoadmap.md) | **Now / Next / Later** — current state → live Dev |
| [CLOUDFORMATION_PLAN.md](./specifications/CLOUDFORMATION_PLAN.md) | Strategic IaC milestones, governance, risks |
| [CLOUDFORMATION_CHECKLIST.md](./specifications/CLOUDFORMATION_CHECKLIST.md) | Tactical task index R010–R130 |
| [CloudEnvironmentPlan.md](./specifications/CloudEnvironmentPlan.md) | Platform/runtime scope (Shared-Services, Dev, staging, prod) |
| [DEPENDENCY_MOVE.md](./specifications/DEPENDENCY_MOVE.md) | CodeArtifact migration (org, infra, consumer rollout) |
| [aws-platform.yaml](./specifications/aws-platform.yaml) | Canonical region, account IDs, CodeArtifact, SSO, GitHub org vars |
| [INFO.md](./specifications/INFO.md) | As-built CodeArtifact CLI transcripts (import reference) |
| [InfrastructureDiagram.svg](./specifications/InfrastructureDiagram.svg) | Platform / account diagram |

Product architecture (journeys, services, local DEV diagrams) remains in [mentorhub/Specifications](https://github.com/mentor-forge/mentorhub/tree/main/Specifications).
