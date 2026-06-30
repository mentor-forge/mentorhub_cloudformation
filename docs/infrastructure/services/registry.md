# Registry (GHCR, ECR, CodeArtifact)

**Feature:** F001, F002

## Three registries, three jobs

| Registry | Purpose | When |
|----------|---------|------|
| **CodeArtifact** | Private pip/npm libraries (`api_utils`, `spa_utils`) | Build time |
| **GHCR** | Application container images | Build output; developer pulls |
| **ECR** | AWS runtime copy of container images | Deploy time (ECS pull) |

## Image pipeline (F001)

```text
merge main
  → GitHub Actions build (deps from CodeArtifact)
  → push ghcr.io/mentor-forge/<repo>:latest
  → push <account>.dkr.ecr.us-east-1.amazonaws.com/<repo>:latest  (same digest)
```

GHCR remains canonical for `mh pull`. ECR is the **proxy layer** for AWS — not a separate build.

## Promotion tags

| Tag | Meaning |
|-----|---------|
| `:latest` | Latest merge to main |
| `:test` | Promoted to test tenant |
| `:staging-YYYYMMDD.N` | Staging release |
| `:v1.2.3` | Production release |

Deployed ECS tasks pin **digest**, not floating tags.

## CodeArtifact (F002)

- Domain: `mentor-forge` in Shared-Services (`560167829275`)
- Repos: `mentorhub-pypi`, `mentorhub-npm`
- Under CloudFormation via R020 import

## GHCR retirement ([D-5](../infrastructure.yaml))

After ECR + ECS path proven (R100), evaluate retiring GHCR for AWS-only environments. Developers may still use GHCR until explicitly migrated.

See [DEPENDENCY_MOVE.md](../../specifications/DEPENDENCY_MOVE.md).
