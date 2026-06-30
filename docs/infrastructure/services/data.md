# Data (DocumentDB)

**AWS:** Amazon DocumentDB  
**Tasks:** R050, R080 · **Feature:** F003

## Mapping from local

| Local | Cloud |
|-------|-------|
| `mongo:7.0.5` | DocumentDB (MongoDB-compatible API) |
| `MONGO_DB_NAME: mentor_hub` | Per-tenant database name |
| `mongodb_api` configure | One-shot ECS task on deploy |

## Multi-tenant Dev

One DocumentDB **cluster**, multiple **databases**:

| Tenant | Database |
|--------|----------|
| dev | `mentorhub_dev` |
| test | `mentorhub_test` |
| training | `mentorhub_training` |

Connection strings in Secrets Manager per tenant.

## Collections

Logical collections (Journey, Profile, Event, etc.) live inside each database — they are not separate AWS services. See product [architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml).

## Backups

- Dev: automated backups, shorter retention
- Staging: match prod policy at reduced window
- Production: multi-AZ, point-in-time recovery, tested restore runbook

## Security

- DocumentDB in private subnets only
- Security group: ECS task SG → DocumentDB SG on 27017
- TLS required in cloud (`MONGODB_REQUIRE_TLS: True`)
