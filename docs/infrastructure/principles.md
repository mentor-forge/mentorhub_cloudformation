# Architectural principles

**Status:** Planning roadmap draft

## Immutable images

Container images are the unit of promotion. CI builds once when a feature merges to `main`. The same image digest moves through environments — we do not rebuild for deployment.

- **GHCR** (`ghcr.io/mentor-forge/*`) — canonical registry for developer pulls and CI output today
- **ECR** (Shared-Services) — AWS runtime registry; receives the same digest via dual-push (F001)

## Promotion, not rebuild

```text
merge main → build → push digest to GHCR + ECR
                → tag alias (dev-latest, test, staging-*, v*)
                → deploy pins ECS task definition to digest
```

## Tenancy

| Environment | Model |
|-------------|-------|
| Local | Single stack; optional compose profiles for isolation |
| MentorHub-Dev | Multi-tenant (dev, test, training); shared VPC, DocumentDB cluster, ECS cluster |
| Staging | Single tenant; mirrors prod topology; scale-to-zero when idle |
| Production | Single tenant; HA, backups, WAF |

Logical isolation in Dev uses **separate DocumentDB databases** and **tenant-scoped secrets/config**, not separate clusters per tenant.

## Edge and routing

All user traffic enters through **API Gateway** in cloud environments. Multiple journey SPAs share one public entry; routes distinguish `/coordinator`, `/mentor`, `/mentee`, `/customer`. Private ECS tasks are not directly internet-facing.

Local Developer Edition uses direct localhost ports; an optional edge proxy can mimic gateway routing when needed.

## Specifications as inputs

- **infrastructure.yaml** — platform intent (this planning roadmap)
- **architecture.yaml** (mentorhub) — product journeys and services
- **CloudFormation templates** — implementation; one stack per PR
- **Task files** — executable units of work

Templates implement intent; they do not redefine product goals.
