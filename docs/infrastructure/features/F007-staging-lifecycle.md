# F007 — Staging lifecycle

**Status:** Later  
**Tasks:** R120

## Goal

Production-mirror environment for release validation; spin down when idle.

## Deliverables

- Staging account or isolated stack (D-4)
- Same topology as production at reduced sizing
- `deploy-release --env staging --digest` automation
- Scale-to-zero runbook

## Done when

- Promote digest from Dev → Staging without rebuild
- Spin down reduces cost to near-zero
- Staging smoke tests pass before prod promotion

## Depends on

- F006 (Dev fully operational)
- D-4 (account model)

See [environments/staging.md](../environments/staging.md).
