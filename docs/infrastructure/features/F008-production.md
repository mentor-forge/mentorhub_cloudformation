# F008 — Production

**Status:** Later  
**Tasks:** R130

## Goal

Live single-tenant MentorHub with HA, backups, production IdP, Stripe live, and WAF.

## Deliverables

- Production account infrastructure
- Multi-AZ DocumentDB, backup/restore tested
- Production Cognito or commercial IdP
- SES production domain
- Stripe live mode
- WAF on API Gateway
- `ArchitectureDiagram.production.svg`

## Done when

- Production sign-off checklist complete (sre_standards)
- Only signed-off staging digests deploy to production
- HA and backup runbooks tested

## Depends on

- F007 (staging validation path)

See [environments/production.md](../environments/production.md).
