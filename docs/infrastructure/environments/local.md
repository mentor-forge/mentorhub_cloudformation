# Local environment (Developer Edition)

**Status:** Planning roadmap draft  
**Compose file:** [mentorhub/DeveloperEdition/docker-compose.yaml](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/docker-compose.yaml)

## Purpose

Full MentorHub stack on a developer machine via Docker Compose and the `mh` CLI. Parity target for cloud Dev — same container images, same journey boundaries.

## Service mapping

| Compose service | Cloud equivalent |
|-----------------|------------------|
| `welcome` | Cognito Hosted UI + optional static welcome |
| `*_spa` | ECS Fargate or S3+CloudFront behind API Gateway |
| `*_api` | ECS Fargate (private) |
| `mongodb` | Amazon DocumentDB |
| `mongodb_api` | ECS one-shot configure job |
| *(missing)* MailHog | Amazon SES |
| *(commented)* stripe mock | Stripe test mode |

## Gaps to close

| Gap | Priority | Notes |
|-----|----------|-------|
| **MailHog** | High | Mock SMTP; maps to SES. Referenced in ArchitectureDiagram.dev.guide but not in compose today |
| **Stripe mock** | Medium | Commented in compose; enable for customer journey billing tests |
| **Edge proxy** | Low | Optional nginx/traefik to mimic API Gateway path routing |
| **runbook_api** | Low | Automation; optional in local stack |

## Isolation

Compose **profiles** (`customer`, `mentor`, `coordinator`, etc.) allow partial stacks. Cloud Dev uses tenant namespaces instead — see [dev-multi-tenant.md](./dev-multi-tenant.md).

## Images

Developers pull `ghcr.io/mentor-forge/*:latest` via `mh pull`. After F001, the same digest is available in ECR for AWS deploys.
