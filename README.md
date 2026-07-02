# MentorHub CloudFormation

Infrastructure-as-code for MentorHub on AWS. CloudFormation templates, parameters, and deployment scripts live in this repository.

**Product architecture** (journeys, services, data domains) is in [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml). This README describes the **target AWS platform** — accounts, environments, services, and how container images move through the system.

---

## AWS organization

```text
AWS Organization
└── Root
    ├── Management              — organization, Identity Center, billing
    ├── Shared-Services         — shared platform services (no application workloads)
    ├── mentorhub-dev           — multi-tenant development and short-lived environments
    ├── mentorhub-staging       — production mirror; may be shut down between releases
    └── mentorhub-production    — live single-tenant production
```

| Setting | Value |
|---------|-------|
| Primary workload region | `us-east-1` |
| IAM Identity Center region | `us-east-2` |
| Canonical platform config | [`config/aws-platform.yaml`](./config/aws-platform.yaml) |

### Deployment status

| Account | Status |
|---------|--------|
| **Shared-Services** (`560167829275`) | Created. CodeArtifact operational. ECR and remaining shared stacks in progress. |
| **mentorhub-dev** | Created. Workload infrastructure (VPC, DocumentDB, ECS, edge) not yet deployed. |
| **mentorhub-staging** | Not created. |
| **mentorhub-production** | Not created. |

---

## AWS accounts and services

### Shared-Services

Account for platform services shared across MentorHub AWS accounts. Does not run application containers or tenant workloads.

| Service | AWS |
|---------|-----|
| Logging | CloudTrail |
| Package management | CodeArtifact |
| Container registry | Elastic Container Registry (ECR) |
| Log analytics | Elasticsearch, Logstash, Kibana (ELK) |
| Metrics and dashboards | Prometheus, Grafana |
| Infrastructure automation | CloudFormation |
| GitHub automation access | IAM OIDC provider and roles |

CLI profile: `mentorhub-shared`

### mentorhub-dev

Multi-tenant account for development, test, training, conference, and other short-lived environments. Tenants share VPC, DocumentDB cluster, and ECS cluster; each tenant has its own database and configuration.

| Service | AWS | Name / detail |
|---------|-----|---------------|
| Logging | CloudTrail | |
| Network | VPC | `mentorhub-dev-vpc` — `10.0.0.0/16` |
| Container runtime | ECS | `mentorhub-dev-ecs` |
| Database | DocumentDB | `mentorhub-dev-documentdb` — one cluster, database per tenant |
| Identity | Cognito | `mentorhub-dev-cognito` |
| DNS | Route 53 | `mentorhub-dev-route53` |
| Email | SES | `mentorhub-dev-ses` |
| Object storage | S3 | `mentorhub-dev-s3` |
| Secrets | Secrets Manager | tenant-scoped |
| Log collection | CloudWatch Logs | forwards to Shared-Services ELK |
| Metrics | Prometheus scrape / ADOT | forwards to Shared-Services Grafana |

**Tenants** (logical environments within the account):

| Tenant | Image tag | Database |
|--------|-----------|----------|
| `dev` | `latest` | `mentorhub-dev` |
| `test` | `test` | `mentorhub-test` |
| `training` | `training` | `mentorhub-training` |
| `conference` | *(promoted from prod or latest)* | `mentorhub-conference` |

Additional short-lived tenants (for example `conference`) follow the same model: shared infrastructure, separate database, removed when no longer needed.

CLI profile: `mentorhub-dev`

### mentorhub-staging

Single-tenant account that mirrors production topology. May be scaled down or shut down between releases.

| Service | AWS |
|---------|-----|
| Logging | CloudTrail |
| Network | VPC (`mentorhub-staging-vpc`) |
| Container runtime | ECS (`mentorhub-staging-ecs`) |
| Database | DocumentDB (`mentorhub-staging-documentdb`) |
| Identity | Cognito |
| DNS | Route 53 |
| Email | SES |
| Object storage | S3 |

| Tenant | Image tag | Database |
|--------|-----------|----------|
| `staging` | `staging` | `mentorhub-staging` |

### mentorhub-production

Single-tenant live production environment.

| Service | AWS |
|---------|-----|
| Logging | CloudTrail |
| Network | VPC (`mentorhub-production-vpc`) |
| Container runtime | ECS (`mentorhub-production-ecs`) |
| Database | DocumentDB (`mentorhub-production-documentdb`) |
| Identity | Cognito |
| DNS | Route 53 |
| Email | SES |
| Object storage | S3 |

| Tenant | Image tag | Database |
|--------|-----------|----------|
| `production` | `production` | `mentorhub-production` |

---

## Environments and tenancy

| Environment | AWS account | Tenancy | Notes |
|-------------|-------------|---------|-------|
| Local | Developer machine (Docker Compose) | Single stack | See [mentorhub Developer Edition](https://github.com/mentor-forge/mentorhub/tree/main/DeveloperEdition) |
| Development / Test / Training / Conference | `mentorhub-dev` | Multi-tenant | Shared DocumentDB cluster; one database per tenant |
| Staging | `mentorhub-staging` | Single tenant | Mirror of production; spin down when not in use |
| Production | `mentorhub-production` | Single tenant | Live environment |

---

## Change management

Container images are immutable. CI builds once; **promote** moves images between registry tags; **deploy** rolls out ECS for a tenant or environment using those tags. See [ARCHITECTURE.md](./ARCHITECTURE.md#cicd-and-change-management) for tags vs digests, guardrails, and examples.

```text
merge to main
  → build container image
  → push to GHCR (:latest)
  → ECR retrieves image from GHCR (same digest)
  → promote (tag → tag, e.g. :latest → :test, :production → :conference)
  → deploy (ECS rollout for tenant/env using configured promotion tag)
```

Typical promotion path:

```text
DEV  →  TEST  →  STAGING  →  PRODUCTION
                              └→ CONFERENCE (short-lived tenant in dev account)
```

At deploy time, automation resolves the promotion tag to an image digest for audit and reproducibility — operators work in tags, not raw digests.

---

## CI/CD

| Stage | Mechanism |
|-------|-----------|
| **CI** | GitHub Actions builds on merge to `main` and pushes images to **GHCR** (`ghcr.io/mentor-forge/*`) |
| **Registry mirror** | **ECR** (Shared-Services) receives the same digest from GHCR |
| **CD** | **Promote** workflows retag images in ECR (`from` → `to`); **deploy** workflows roll ECS for a tenant/environment using its configured promotion tag |

Build dependencies (Python and npm packages) are resolved from **CodeArtifact** in Shared-Services during CI.

### Deploy automation (examples)

| Action | Description |
|--------|-------------|
| Promote `:latest` → `:test` | Tag current `:latest` images as `:test` in ECR (no rebuild) |
| Deploy `dev` tenant | Roll out ECS services configured for tag `:latest` |
| Promote `:production` → `:conference` | Tag prod-known-good images as `:conference` for demo |
| Deploy `conference` tenant | Stand up conference tenant in `mentorhub-dev`; tear down after event |
| Promote → `:staging` / `:production` | Guarded promotions; then deploy staging or production stack |

CD is driven by **tag/deploy** GitHub Actions workflows — not by rebuilding images at deploy time.

---

## Repository layout

```text
mentorhub_cloudformation/
├── README.md                    # Platform overview (accounts, tenancy, CI/CD)
├── ARCHITECTURE.md              # SA peer review — service rationale and design findings
├── config/                      # Canonical platform configuration (as-built state)
│   └── aws-platform.yaml        # Account IDs, CodeArtifact, SSO, observability targets
├── docs/                        # Diagrams and archived planning documents
│   ├── InfrastructureDiagram.svg
│   ├── ArchitectureDiagram.dev.svg
│   ├── ArchitectureDiagram.dev.drawio
│   ├── guides/                  # Diagram completion guides
│   └── archive/                 # Superseded planning docs — remove 2026-08-01
├── import/                      # CloudFormation resource-import definitions
│   └── codeartifact-resources-to-import.json
├── parameters/                  # Stack parameter files per account/environment
│   ├── shared-services.json
│   ├── dev.json
│   ├── staging.json
│   └── production.json
├── scripts/                     # Deploy and import helper scripts
│   ├── deploy-stack.sh
│   └── import-codeartifact-stack.sh
├── tasks/                       # SRE implementation tasks (R010–R130)
├── templates/                   # CloudFormation templates
│   ├── shared-services/         # Shared-Services account stacks (CodeArtifact, ECR, OIDC)
│   └── dev/                     # mentorhub-dev workload stacks (VPC, ECS, DocumentDB, edge)
└── .github/workflows/           # CI (template lint on pull request)
    └── cfn-lint.yml
```

Stack naming convention: `mentorhub-<env>-<component>`.

---

## Related documentation

| Document | Location |
|----------|----------|
| Architecture rationale and SA review | [`ARCHITECTURE.md`](./ARCHITECTURE.md) |
| Platform overview (accounts, tenancy, CI/CD) | [`README.md`](./README.md) |
| AWS account IDs, SSO, CodeArtifact | [`config/aws-platform.yaml`](./config/aws-platform.yaml) |
| Platform diagram | [`docs/InfrastructureDiagram.svg`](./docs/InfrastructureDiagram.svg) |
| Cloud DEV runtime diagram | [`docs/ArchitectureDiagram.dev.svg`](./docs/ArchitectureDiagram.dev.svg) |
| Product architecture | [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) |
| Archived planning docs | [`docs/archive/`](./docs/archive/) — **remove 8/1/26** |

Rationale for service choices and operational runbooks: see [`ARCHITECTURE.md`](./ARCHITECTURE.md).
