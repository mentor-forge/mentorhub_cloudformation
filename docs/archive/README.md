# Archived planning documents

These files were superseded by the [repository README](../../README.md) (TO-BE platform overview) and [`config/aws-platform.yaml`](../../config/aws-platform.yaml) (as-built platform state). Kept for historical reference only.

## Retention

| Milestone | Date |
|-----------|------|
| **Archive removal** | **August 1, 2026** (`2026-08-01`) |

After **8/1/26**, this folder and its contents will be deleted from the repository. Anything still needed must live in [README.md](../../README.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), or [config/aws-platform.yaml](../../config/aws-platform.yaml) before that date.

Before removal, verify:

- No open links from `mentorhub` or other repos point at `docs/archive/` paths (see `mentorhub` task R110)
- Completed work is captured in `config/aws-platform.yaml` (e.g. CodeArtifact as-built state formerly in `INFO.md`)

---

| File | Former purpose |
|------|----------------|
| [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) | CodeArtifact migration from git-based dependencies |
| [CloudEnvironmentPlan.md](./CloudEnvironmentPlan.md) | Platform/runtime scope across environments |
| [LiveDevPlan.md](./LiveDevPlan.md) | Integrated critical path to live Dev |
| [CloudDevRoadmap.md](./CloudDevRoadmap.md) | Now / Next / Later agile rhythm |
| [CLOUDFORMATION_PLAN.md](./CLOUDFORMATION_PLAN.md) | Strategic IaC milestones |
| [CLOUDFORMATION_CHECKLIST.md](./CLOUDFORMATION_CHECKLIST.md) | Tactical task index R010–R130 |
| [roadmap.yaml](./roadmap.yaml) | Product + platform roadmap (YAML) |
| [INFO.md](./INFO.md) | CodeArtifact CLI transcripts from initial provisioning |
