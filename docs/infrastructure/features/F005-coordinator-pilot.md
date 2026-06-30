# F005 — Coordinator pilot in cloud

**Status:** Planned  
**Tasks:** R080

## Goal

First end-to-end journey in MentorHub-Dev: login → coordinator SPA → coordinator API → DocumentDB.

## Scope

- Deploy coordinator_api + coordinator_spa (+ mongodb_api configure job)
- `dev` tenant database seeded
- Public URL via API Gateway

## Done when

- Manual smoke: sign in, load coordinator UI, read/write data in DocumentDB
- Rollback procedure documented (previous task definition / digest)

## Depends on

- F001 (ECR images)
- F003 (platform)
- F004 (edge + auth)

## Milestone

**"Dev is live"** per [CloudDevRoadmap.md](../../specifications/CloudDevRoadmap.md) Phase 3.
