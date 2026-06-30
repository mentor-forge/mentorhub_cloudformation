# Dev multi-tenant environment

**Status:** Planning roadmap draft  
**Account:** MentorHub-Dev  
**Feature:** [F003](../features/F003-dev-platform.md), [F004](../features/F004-edge-and-auth.md)

## Model

One AWS account hosts multiple **logical tenants** on **shared infrastructure**:

```text
MentorHub-Dev
├── Shared: VPC, NAT, DocumentDB cluster, ECS cluster, API Gateway
└── Tenants: dev | test | training
    ├── Separate DocumentDB database per tenant
    ├── Tenant-scoped secrets (Secrets Manager)
    └── ECS services per journey (or shared services with tenant config — TBD)
```

## Tenants

| Tenant | Database | Image tag alias | Hostname (TBD D-3) |
|--------|----------|-----------------|-------------------|
| `dev` | `mentorhub_dev` | `dev-latest` | `dev.mentorhub.example` |
| `test` | `mentorhub_test` | `test` | `test.mentorhub.example` |
| `training` | `mentorhub_training` | `training` | `training.mentorhub.example` |

## Routing ([D-8](../infrastructure.yaml))

**Preferred:** path-based via API Gateway on a shared hostname:

```text
/coordinator/* → coordinator tenant services
/mentor/*      → mentor tenant services
/mentee/*      → mentee tenant services
/customer/*    → customer tenant services
```

**Alternative:** hostname per tenant (`dev.*`, `test.*`). Decision blocks R070.

## Deploy automation (target)

```text
deploy --tenant test --digest sha256:abc... --journeys coordinator,mentor
```

Promotes an immutable ECR digest to the test tenant without rebuilding.

## Shared DocumentDB

- One DocumentDB cluster per Dev account (cost and ops simplicity)
- **Never** share collections across tenants — database name is the isolation boundary
- `mongodb_api` configure job runs per tenant database on deploy

## Exit criteria (Dev platform live)

- [ ] VPC + private subnets + NAT (R040)
- [ ] DocumentDB + secrets (R050)
- [ ] ECS cluster + logging (R060)
- [ ] API Gateway + DNS/TLS (R070)
- [ ] Coordinator pilot on `dev` tenant (R080)
