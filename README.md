# MentorHub CloudFormation

Infrastructure-as-code for MentorHub on AWS. CloudFormation templates, parameters, and deployment scripts live in this repository.

**Product architecture** (journeys, services, data domains) is in [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml). This README describes the **target AWS platform** — accounts, environments, services, and how container images move through the system.

---

## Open source

MentorHub application **source code** is open on GitHub under the project license. This repository is Mentor Forge’s **reference AWS implementation** — not the only way to run the product.

| What we publish openly | What we do not provide as a public service |
|------------------------|---------------------------------------------|
| Application and library source repos | Pre-built **public container images** (no public GHCR) |
| Runtime contract (APIs, env vars, JWT/OIDC expectations) | **CodeArtifact** access without invitation |
| **Demo tenant (target)** in `mentorhub-dev` — minimal product trial via hosted URL | Anonymous local container builds (require CodeArtifact + contributor auth) |
| [Developer Edition](https://github.com/mentor-forge/mentorhub/tree/main/DeveloperEdition) (invited contributors: ECR pull + CodeArtifact via `mh` / SSO) | `GITHUB_TOKEN` / GHCR for local dev (interim until R100) |
| This CloudFormation repo as an AWS reference design | Turnkey multi-cloud IaC |

**Mentor Forge operators** build on merge to `main`, resolve dependencies from **CodeArtifact**, push images to **ECR** (Shared-Services), and deploy to **ECS** using the workflows and roles documented in [docs/github-ci.md](./docs/github-ci.md). Contributors who need the same pipeline are **invited** to the organization and AWS access model — we do not subsidize unbounded use of shared build infrastructure.

**Third-party implementers** who want to run MentorHub in their own cloud (AWS, GCP, Azure, on-prem, etc.) should expect to:

1. **Fork** the application repositories they need.
2. **Replace dependency management** — publish or vendor `api-utils` / `spa_utils` equivalents on their own PyPI/npm (or git pins), not Mentor Forge CodeArtifact.
3. **Implement their own CI/CD** — build containers and push to **their** registry; we do not publish images for external pull.
4. **Provide their own IaC** — use this repo as a reference for AWS if helpful, or map the same containers and contracts to another platform.

That boundary is intentional: **open source software**, **operator-specific implementation**. See [ARCHITECTURE.md — Open source](./ARCHITECTURE.md#open-source-and-third-party-implementation) for rationale and intern takeaways.

---

## AWS organization

```text
AWS Organization
└── Root
    ├── Management (680206182977)     — organization, Identity Center, billing
    ├── Shared-Services (560167829275) — shared platform services (no application workloads)
    ├── mentorhub-dev (083141433373)  — multi-tenant development and short-lived environments
    ├── mentorhub-staging             — production mirror; may be shut down between releases (not created)
    └── mentorhub-production          — always-on live single-tenant production (not created)
```

| Setting | Value |
|---------|-------|
| Primary workload region | `us-east-1` — CodeArtifact, ECR, ECS, DocumentDB, ALB |
| IAM Identity Center region | `us-east-2` — SSO sign-in only (`aws sso login`); not where workloads run |
| Canonical platform config | [`config/aws-platform.yaml`](./config/aws-platform.yaml) |

**Two regions by design:** Identity Center’s home region (`us-east-2`) is fixed at org enablement and is independent of where application resources deploy (`us-east-1`). After SSO login, CLI and service calls use **`us-east-1`** (profile `region` or `--region us-east-1`). Do not collapse these into one region.

### Deployment status

| Account | Status |
|---------|--------|
| **Management** (`680206182977`) | Active. Organization root, Identity Center, billing. |
| **Shared-Services** (`560167829275`) | Created. CodeArtifact operational. ECR and remaining shared stacks in progress. |
| **mentorhub-dev** (`083141433373`) | Created. Workload infrastructure (VPC, DocumentDB, ECS, edge) not yet deployed. |
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
| Log analytics | Amazon OpenSearch Service, OpenSearch Dashboards |
| Metrics and dashboards | Prometheus, Grafana |
| Infrastructure automation | CloudFormation |
| GitHub automation access | IAM OIDC provider and roles |

CLI profile: `mentorhub-shared`

### mentorhub-dev

Multi-tenant account for development, test, training, conference, and other short-lived environments. Tenants share VPC, DocumentDB cluster, and ECS cluster; each tenant has its own database and configuration.

| Service | AWS | Name / detail |
|---------|-----|---------------|
| Logging | CloudTrail | |
| Network | VPC | `mentorhub-dev-vpc` — `10.0.0.0/16`; interface endpoints for ECR, S3, Secrets Manager (R040) |
| Container runtime | ECS | `mentorhub-dev-ecs` |
| Database | DocumentDB | `mentorhub-dev-documentdb` — one cluster, database per tenant |
| Identity | Cognito | `mentorhub-dev-cognito` |
| DNS | Route 53 | `mentorhub-dev-route53` |
| Email | SES | `mentorhub-dev-ses` |
| Object storage | S3 | `mentorhub-dev-s3` |
| Secrets | Secrets Manager | tenant-scoped |
| Log collection | CloudWatch Logs | forwards to Shared-Services OpenSearch |
| Metrics | Prometheus scrape of each API `GET /metrics` | Shared-Services Grafana |

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

| Service | AWS | Name / detail |
|---------|-----|---------------|
| Logging | CloudTrail | |
| Network | VPC | `mentorhub-staging-vpc` — CIDR TBD |
| Container runtime | ECS | `mentorhub-staging-ecs` |
| Database | DocumentDB | `mentorhub-staging-documentdb` |
| Identity | Cognito | `mentorhub-staging-cognito` |
| DNS | Route 53 | `mentorhub-staging-route53` |
| Email | SES | `mentorhub-staging-ses` |
| Object storage | S3 | `mentorhub-staging-s3` |
| Edge | ALB + ACM | HTTPS entry; WAF optional in staging |

| Tenant | Image tag | Database |
|--------|-----------|----------|
| `staging` | `staging` | `mentorhub-staging` |

### mentorhub-production

Single-tenant **always-on** live production environment.

| Service | AWS | Name / detail |
|---------|-----|---------------|
| Logging | CloudTrail | |
| Network | VPC | `mentorhub-production-vpc` — CIDR TBD |
| Container runtime | ECS | `mentorhub-production-ecs` |
| Database | DocumentDB | `mentorhub-production-documentdb` |
| Identity | Cognito | `mentorhub-production-cognito` |
| DNS | Route 53 | `mentorhub-production-route53` |
| Email | SES | `mentorhub-production-ses` |
| Object storage | S3 | `mentorhub-production-s3` |
| Edge | ALB + ACM + **WAF** | WAF web ACL on ALB **required before go-live** (R130) |
| Database ops | DocumentDB backups | Automated snapshots; retention and restore test defined before go-live (R130) |

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
| Production | `mentorhub-production` | Single tenant | Always-on live environment |

---

## Change management

Container images are immutable. CI builds once; **promote** moves images between registry tags; **deploy** rolls out ECS for a tenant or environment using those tags. See [ARCHITECTURE.md](./ARCHITECTURE.md#cicd-and-change-management) for tags vs digests, guardrails, and examples.

```text
merge to main
  → build container image (CodeArtifact deps via GitHub OIDC)
  → push to ECR (Shared-Services, :latest)
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
| **CI** | GitHub Actions builds on merge to `main` and pushes images to **ECR** (Shared-Services) |
| **CD** | **Promote** workflows retag images in ECR (`from` → `to`); **deploy** workflows roll ECS for a tenant/environment using its configured promotion tag |

Build dependencies (Python and npm packages) are resolved from **CodeArtifact** in Shared-Services during CI. Journey API/SPA workflows assume an IAM role via **GitHub OIDC** (`AWS_ROLE_ARN_READ` org secret); library repos publish on `v*` tags with `AWS_ROLE_ARN_PUBLISH`.

**GitHub org configuration** (variables, secrets, workflow patterns, repo inventory): [`docs/github-ci.md`](./docs/github-ci.md). Canonical values: [`config/aws-platform.yaml`](./config/aws-platform.yaml) (`github_org_variables`, `github_org_secrets`, `github_ci`).

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
| GitHub org CI, secrets, workflows | [`docs/github-ci.md`](./docs/github-ci.md) |
| Cross-account ECR pull and pull-through cache | [`docs/ecr-cross-account.md`](./docs/ecr-cross-account.md) |
| Platform diagram | [`docs/InfrastructureDiagram.svg`](./docs/InfrastructureDiagram.svg) |
| Cloud DEV runtime diagram | [`docs/ArchitectureDiagram.dev.svg`](./docs/ArchitectureDiagram.dev.svg) |
| Product architecture | [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) |
| Archived planning docs | [`docs/archive/`](./docs/archive/) — **remove 8/1/26** |

Rationale for service choices and operational runbooks: see [`ARCHITECTURE.md`](./ARCHITECTURE.md).
