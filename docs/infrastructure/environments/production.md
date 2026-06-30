# Production environment

**Status:** Planning roadmap draft  
**Feature:** [F008](../features/F008-production.md) · **Tasks:** R130

## Purpose

Live **single-tenant** MentorHub for real users. Highest availability, security, and change-control requirements.

## Topology

| Component | Production standard |
|-----------|---------------------|
| Account | Dedicated `mentorhub-production` (recommended) |
| Database | DocumentDB multi-AZ, automated backups |
| Compute | ECS Fargate, min capacity > 0 |
| Edge | API Gateway + ACM + Route 53 + WAF |
| Identity | Commercial IdP (Cognito or external OIDC) |
| Email | SES production domain, DKIM/SPF |
| Payments | Stripe live mode |
| Secrets | Secrets Manager; no default JWT secrets |
| Observability | CloudWatch alarms, CloudTrail, runbooks |

## Deploy

Only **signed-off release digests** promoted from Staging:

```text
staging digest (validated) → change control approval → production deploy
```

No direct deploy from `main` or Dev tenants.

## Diagram

`ArchitectureDiagram.production.svg` — to be created at R130 / R110.

## Sign-off

Production checklist in [sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md) must be complete before first live cutover.
