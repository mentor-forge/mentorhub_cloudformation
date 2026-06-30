# Staging environment

**Status:** Planning roadmap draft  
**Feature:** [F007](../features/F007-staging-lifecycle.md) · **Tasks:** R120

## Purpose

A **mirror of production** used to validate releases before production deploy. May be **spun down** between releases to control cost.

## Topology

Same service layout as Production (all journeys, gateway, Cognito, SES, Stripe test mode) at smaller sizing.

| Aspect | Staging | Production |
|--------|---------|------------|
| Tenants | 1 (`staging`) | 1 (`production`) |
| HA | Reduced | Full |
| Stripe | Test mode | Live |
| WAF | Optional | Required |
| Scale | Can go to zero | Always on |

## Lifecycle

**Spin up** (before a release test):

```text
deploy-release --env staging --digest <immutable-ecr-digest>
```

**Spin down** (after validation or idle period):

- ECS desired count → 0 on all services
- Optional: pause/smaller DocumentDB tier if supported
- DNS may remain; gateway returns maintenance response

## Image promotion

Staging receives **the same digest** tested in Dev/Test tenants — no rebuild. Promotion is a change-control action, not a CI event.

## Account model ([D-4](../infrastructure.yaml))

Options under review:

1. **Separate account** (`mentorhub-staging`) — stronger isolation (recommended)
2. **Shared account** with separate VPC — lower cost, weaker blast-radius separation

Blocks R120 until decided.
