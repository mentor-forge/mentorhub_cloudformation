# F004 — Edge routing and authentication

**Status:** Planned  
**Tasks:** R070

## Goal

Public HTTPS entry via API Gateway; routing to all journey SPAs; auth story for cloud Dev.

## Deliverables

- API Gateway HTTP API + VPC Link + internal ALB
- Route 53 + ACM (or documented HTTP interim per D-3)
- Cognito user pool **or** interim welcome JWT (D-2)
- S3 buckets if needed for static assets

## Routing

Path-based routes: `/coordinator`, `/mentor`, `/mentee`, `/customer`, `/webhooks/stripe`.

See [services/edge.md](../services/edge.md).

## Decisions required

- D-2: Cognito vs welcome JWT for first pilot
- D-3: Owned domain + TLS
- D-7: ECS nginx vs S3+CloudFront for SPAs
- D-8: Hostname vs path tenant routing

## Done when

API Gateway reachable; auth flow documented; coordinator SPA can load via public URL.

## Unblocks

F005 (coordinator pilot)
