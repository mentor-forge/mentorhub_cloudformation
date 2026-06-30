# Compute (ECS)

**AWS:** Amazon ECS on Fargate  
**Tasks:** R060, R080, R090, R100 · **Feature:** F003, F005, F006

## Cluster

One ECS cluster per account (`mentorhub-dev-ecs`, etc.). All journey services run as Fargate tasks in private subnets.

## Services (per journey)

| Service | Image source | Notes |
|---------|--------------|-------|
| `coordinator_api` | ECR digest | Flask API |
| `coordinator_spa` | ECR digest | nginx static |
| `mentor_api` / `mentor_spa` | ECR digest | |
| `mentee_api` / `mentee_spa` | ECR digest | |
| `customer_api` / `customer_spa` | ECR digest | |
| `mongodb_api` | ECR digest | Run as one-shot task on deploy |

## Task definitions

- Pin **image digest**, not floating `:latest`, in deployed environments
- Secrets from Secrets Manager (`JWT_SECRET`, `MONGO_CONNECTION_STRING`, etc.)
- CloudWatch Logs via `awslogs` driver

## Deploy (F006 / R100)

```text
merge main → GHCR + ECR push
         → automation updates task definition with new digest
         → ECS rolling deploy per service/tenant
```

## Scaling

- Dev: min 1 per active tenant service
- Staging: 0 when spun down
- Production: min > 0, auto-scaling on CPU/request count (TBD)
