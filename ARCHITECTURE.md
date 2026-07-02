# MentorHub AWS Architecture — Solutions Architect Review

**Reviewer:** Senior AWS Solutions Architect (peer review)  
**Status:** Target architecture with partial deployment  
**Audience:** Interns (learn the *why*), Junior Architect (fix the gaps)  
**Companion docs:** [README.md](./README.md) (platform *what*), [config/aws-platform.yaml](./config/aws-platform.yaml) (as-built values), [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) (product journeys)

---

## Executive summary

MentorHub is a multi-journey web application (coordinator, mentor, mentee, customer) backed by MongoDB-shaped document data, deployed as containerized APIs and SPAs on **Amazon ECS**, with **DocumentDB** as the database, **Amazon Cognito** for identity, and **API Gateway** as the public edge. The platform uses a **multi-account AWS Organization**, separates **shared platform services** from **application workloads**, and promotes **immutable container images** from CI through dev → test → staging → production.

The overall shape is sound for a small team learning AWS operations: account boundaries are in the right places, the registry and package-management split is deliberate, and the dev-account multi-tenancy model controls cost without pretending to be production isolation.

Several items in the junior architect's first pass need correction before staging and production are built. Those are called out in [Findings for the Junior Architect](#findings-for-the-junior-architect).

---

## System context

```text
Developers (local Docker Compose)
        │
        ▼
GitHub (source) ──► GitHub Actions (CI)
        │                    │
        │                    ├──► CodeArtifact (pip/npm libs)
        │                    └──► GHCR (container images)
        │                              │
        │                              ▼
        │                         ECR mirror (Shared-Services)
        │                              │
        ▼                              ▼
IAM Identity Center              ECS (per account/tenant)
(human access)                         │
                                       ├──► DocumentDB
                                       ├──► Cognito
                                       ├──► S3 / SES
                                       └──► Secrets Manager
        ▲
        └── API Gateway + Route 53 + ACM (public HTTPS)
```

**Product workloads:** eight journey repositories (four API + four SPA pairs), plus shared `api_utils` / `spa_utils` libraries, `mongodb_api` configurator, and `runbook_api`.

---

## Account model

| Account | Role | Why it exists |
|---------|------|----------------|
| **Management** | Organization root, billing, Identity Center | Keeps human identity and org governance out of workload accounts. Standard AWS best practice. |
| **Shared-Services** | CodeArtifact, ECR, shared CloudTrail, GitHub OIDC roles | Platform services used by *all* environments but not tied to one app's lifecycle. Prevents "prod account owns the package registry" coupling. |
| **mentorhub-dev** | Multi-tenant dev / test / training / conference | One account, many logical environments, shared VPC and DocumentDB cluster. Minimizes cost and operational overhead while the team is still building. |
| **mentorhub-staging** | Single-tenant prod mirror | Validates releases in prod-like topology without prod blast radius. Designed to **scale down** between releases. |
| **mentorhub-production** | Single-tenant live | Customer-facing environment with stricter controls (HA, backups, WAF — to be implemented). |

### What the intern should remember

**Multi-account is not vanity.** It limits blast radius (a misconfigured dev experiment cannot delete the package registry), simplifies IAM (developers do not need prod power), and makes cost attribution possible per account.

**Shared-Services is not an app account.** Nothing that serves HTTP to end users runs there. If you see an ECS service proposed for Shared-Services, push back.

---

## Services by layer

### Identity and access

| Service | Where | Used for | Why |
|---------|-------|----------|-----|
| **IAM Identity Center** | Management (`us-east-2`) | Human login via SSO | No long-lived IAM users; permission sets map groups (Developer, SRE) to accounts. |
| **IAM OIDC (GitHub)** | Shared-Services | CI/CD authentication | GitHub Actions assumes short-lived roles to push to CodeArtifact and ECR — no access keys in repos. |
| **Amazon Cognito** | Workload accounts | End-user sign-in, JWTs for APIs | Managed user pools; APIs validate tokens instead of implementing auth themselves. |
| **Secrets Manager** | Workload accounts | DB credentials, API keys, tenant config | Secrets are not baked into images; rotation is possible later. |

**Good decision:** OIDC for automation and Identity Center for humans. This is the modern baseline; IAM users with access keys in GitHub secrets is an anti-pattern we avoided.

---

### Build, registry, and delivery

| Service | Where | Used for | Why |
|---------|-------|----------|-----|
| **CodeArtifact** | Shared-Services | Private PyPI and npm (`api-utils`, `spa_utils`) | Shared libraries are versioned packages, not git clones at Docker build time. Reproducible CI, faster builds, audit trail. |
| **GHCR** | GitHub | Primary container registry today | Natural home for GitHub Actions output; developers already pull from `ghcr.io/mentor-forge`. |
| **ECR** | Shared-Services | AWS-side image store for ECS | ECS tasks pull from ECR in-region. Mirrors GHCR digest so deploy does not rebuild. |
| **GitHub Actions** | GitHub | CI build and push | Build once on merge to `main`. |
| **Tag/deploy workflows** | GitHub + AWS | CD promotion and rollout | **Promote** moves tags in ECR; **deploy** rolls ECS using tenant tag config. |

**Promotion path:**

```text
merge main → build → GHCR (:latest) + ECR mirror → promote (tag → tag) → deploy (tenant/env ECS rollout)
```

**Good decision:** Immutable images. CI builds once; promotion moves the **same image** through environments — we do not rebuild at deploy time.

**Unusual (interim):** Dual registry (GHCR **and** ECR). Common during migration from GitHub-centric CI to AWS-centric runtime. Plan to retire GHCR for AWS-only paths once ECR + ECS deploy is proven ([README.md](./README.md) CD section).

---

### Network and edge

| Service | Where | Used for | Why |
|---------|-------|----------|-----|
| **VPC** | Workload accounts | Isolated network for ECS, DocumentDB | Private subnets for workloads; public subnets for NAT and load-balanced entry. `10.0.0.0/16` in dev. |
| **NAT Gateway** | Workload VPC | Outbound internet from private subnets | ECS tasks in private subnets can reach external APIs (Stripe, etc.) without public IPs. |
| **API Gateway (HTTP API)** | Workload accounts | Single HTTPS entry point | Routes `/coordinator`, `/mentor`, `/mentee`, `/customer` to backend services. Hides internal ECS topology. |
| **Route 53** | Workload accounts | DNS hostnames | Maps friendly names to API Gateway / CloudFront. |
| **ACM** | Workload accounts | TLS certificates | Free managed certs for HTTPS. |

**Good decision:** API Gateway in front of private ECS tasks. Internet-facing containers are harder to secure and patch; gateway gives TLS termination, throttling, and a single place for auth integration.

**Open design choice (not yet resolved):** SPA static assets — serve from **ECS (nginx)** containers vs **S3 + CloudFront**. ECS works for parity with local dev; S3 + CloudFront is usually cheaper and more scalable for static files. Decide before R070/R090 implementation.

---

### Compute and data

| Service | Where | Used for | Why |
|---------|-------|----------|-----|
| **ECS on Fargate** | Workload accounts | Run API and SPA containers | No EC2 fleet to patch; pay per task; fits small team's ops capacity. |
| **DocumentDB** | Workload accounts | MongoDB-compatible document store | Product uses MongoDB APIs (`mongodb_api` configurator, Flask + mongo drivers). DocumentDB is AWS-managed with backups and patching. |
| **S3** | Workload accounts | Object storage (uploads, exports, artifacts) | Durable, cheap storage decoupled from container lifecycle. |
| **SES** | Workload accounts | Transactional email | Password reset, notifications. Sandbox in dev; production access requires AWS approval. |

**Good decision:** DocumentDB for a MongoDB-shaped product on AWS. Running self-managed MongoDB on EC2 would burden a small SRE team. Atlas is a valid alternative but adds a second vendor and network path; DocumentDB keeps data in-VPC with IAM and CloudTrail integration.

**Dev multi-tenancy model:** One DocumentDB **cluster**, separate **database** per tenant (`mentorhub-dev`, `mentorhub-test`, etc.). Collections are never shared across tenants.

| Tenant | Typical use |
|--------|-------------|
| `dev` | Daily integration; receives `:latest` |
| `test` | QA / automated acceptance |
| `training` | Workshops and onboarding |
| `conference` | Short-lived demo environment (may promote prod digests) |

**Why share a cluster in dev:** Cost. A DocumentDB cluster has a minimum hourly charge. Four clusters for four tenants would multiply cost without improving dev fidelity. Logical isolation by database name is sufficient for non-production **if** connection strings and secrets are tenant-scoped and access controls are enforced in application config.

**Not acceptable for production:** Production must be single-tenant with its own cluster, backups, and monitoring — which the target architecture already specifies.

---

### Observability and governance

Observability is **layered**: AWS-native services for collection and audit, **ELK** for log search and analysis, **Prometheus + Grafana** for metrics and dashboards.

```text
Application / ECS tasks
        │
        ├──► CloudWatch Logs (ECS default log driver)
        │         │
        │         └──► Logstash / Fluent Bit ──► Elasticsearch ──► Kibana (ELK)
        │
        └──► Prometheus (scrape or ADOT collector) ──► Grafana (dashboards + alerts)

AWS API activity ──► CloudTrail (all accounts)     ← audit, not application logs
AWS service metrics ──► CloudWatch Metrics          ← optional Grafana datasource
```

#### AWS platform layer (all accounts)

| Service | Where | Used for | Why |
|---------|-------|----------|-----|
| **CloudTrail** | All accounts | API audit log | Who changed infrastructure in AWS; compliance and security investigations. Not a substitute for application logs. |
| **CloudWatch Logs** | Workload accounts | ECS task stdout/stderr, API Gateway access logs | Native ECS log driver (`awslogs`); required collection point before forwarding to ELK. |
| **CloudFormation** | All accounts | Infrastructure as code | Reproducible stacks, change sets, import for existing resources (CodeArtifact). |
| **AWS Budgets** | All accounts | Cost alerts | Early warning before surprise bills. |

#### Log analytics — ELK (target)

| Component | Used for | Why |
|-----------|----------|-----|
| **Elasticsearch** | Log storage and full-text search | Query across all journey APIs and tenants; correlate errors across services. |
| **Logstash** (or **Fluent Bit**) | Log ingestion, parsing, enrichment | Normalise ECS/JSON logs; add `tenant`, `environment`, `journey` fields for multi-tenant dev. |
| **Kibana** | Log exploration and visualisations | Familiar OSS tooling; interns learn industry-standard log analysis. |

**Placement (target):** Shared-Services account — one ELK stack serves dev, staging, and production. Workload accounts forward logs cross-account or via CloudWatch subscription filters. Keeps observability cost and ops in one place.

**Intern takeaway:** CloudTrail tells you *who deleted a security group*. Kibana tells you *why the coordinator API returned 500 at 2am*.

#### Metrics and dashboards — Prometheus + Grafana (target)

| Component | Used for | Why |
|-----------|----------|-----|
| **Prometheus** | Time-series metrics (request rate, latency, errors, ECS task health) | Pull-based metrics model fits containers; PromQL is portable; integrates with alert routing. |
| **Grafana** | Dashboards, alerting, on-call views | Single pane for journey health, tenant comparison, and infra metrics; can add CloudWatch as a secondary datasource for DocumentDB/ECS AWS metrics. |

**What to scrape:** ECS service metrics (via **AWS Distro for OpenTelemetry** collector or Prometheus exporters), API Gateway metrics, and application `/metrics` endpoints where exposed.

**Placement (target):** Shared-Services alongside ELK, or co-located on the same ECS cluster dedicated to platform tooling.

#### Good decisions

- **Separate concerns:** CloudTrail (audit) ≠ ELK (application logs) ≠ Prometheus (metrics). Mixing them creates noisy dashboards and wrong retention policies.
- **Centralise observability tooling** in Shared-Services so dev tenants and future staging/prod feed one Kibana and one Grafana — operators do not context-switch per account.
- **ELK + Grafana/Prometheus** teach portable skills (Kibana, PromQL, Grafana) that transfer to any employer; not locked to a single vendor's console.

#### Findings for observability (Junior Architect)

| # | Finding | Recommendation |
|---|---------|----------------|
| F15 | ELK not yet in templates or `architecture.yaml` | Add observability stacks to IaC backlog; decide self-managed ECS vs **Amazon OpenSearch Service** + Kibana (less ops, slightly less "pure ELK"). |
| F16 | No log pipeline design (CloudWatch → ELK path) | Document in templates: Fluent Bit DaemonSet/sidecar vs CloudWatch Logs subscription → Lambda → Logstash. |
| F17 | No tenant/env labels on logs and metrics | Require `tenant`, `environment`, `service`, `journey` labels in all ECS task definitions — required for multi-tenant dev in one Kibana/Grafana. |
| F18 | Prometheus HA and retention not defined | For prod: two Prometheus replicas or Amazon Managed Prometheus; define retention (e.g. 15d metrics, 30d logs). |
| F19 | Grafana auth not defined | Integrate Grafana with Cognito or Identity Center SSO; do not run Grafana open on the internet. |

**Acceptable but unusual:** Running self-managed ELK on ECS instead of Amazon OpenSearch + Managed Grafana/AMP. Valid for learning and cost control at low volume; revisit when log volume or on-call burden grows.

**Good decision:** Importing existing CodeArtifact into CloudFormation instead of delete-and-recreate. CodeArtifact domains are stateful; recreation would break every consumer pipeline.

---

## Environment strategy

| Environment | Account | Tenancy | Fidelity |
|-------------|---------|---------|----------|
| Local | Developer machine | Single Compose stack | Fast feedback; MailHog instead of SES. |
| Dev / Test / Training / Conference | mentorhub-dev | Multi-tenant | Shared infra; separate DB and config. |
| Staging | mentorhub-staging | Single tenant | Prod topology; may power off between releases. |
| Production | mentorhub-production | Single tenant | Live customers. |

**Good decision:** Staging as a **prod mirror that can sleep**. Staging that runs 24/7 often costs nearly as much as prod while providing little extra value for a release cadence measured in weeks, not hours.

**Good decision:** Conference as a **short-lived tenant in dev**, not a fifth account. Demos need prod-like data and images without prod risk or prod cost.

---

## CI/CD and change management

### Tags vs digests — what interns should know

A container **image** is the built artifact (layers + manifest). Registries refer to it in two ways:

| Concept | Example | Mutable? | What it means |
|---------|---------|----------|----------------|
| **Tag** | `:latest`, `:test`, `:staging`, `:production`, `:conference` | **Yes** (floating) | A label pointing at an image. The same tag can be moved to a newer build later. |
| **Digest** | `sha256:abc123…` | **No** | A fingerprint of the exact image bytes. Same digest always means identical content. |

**Floating tag** — a tag that automation or humans reassign over time. After every merge to `main`, CI pushes `coordinator_api:latest`. Tomorrow’s `:latest` is a different image than today’s, even though the tag name did not change.

**Pinned digest** — ECS task definition (or deploy record) stores `image@sha256:abc123…` so the running task cannot silently change when someone pushes a new image under the same tag name.

```text
Tag :test     ──points-to──►  digest sha256:abc…  (today)
Tag :test     ──points-to──►  digest sha256:def…  (tomorrow, after a new promote)

Digest sha256:abc…  always means the same image, forever.
```

**Intern takeaway:** Tags are how we **name promotion channels** (`test`, `staging`, `conference`). Digests are how we **prove** what actually ran. Both are used; they solve different problems.

---

### Target model — promotion tags and ECS stack config

The intended operator model is **tag-driven**, similar to Developer Edition `docker-compose.yaml`:

| Local (Compose) | Cloud (ECS) |
|-----------------|-------------|
| `image: ghcr.io/mentor-forge/coordinator_api:latest` | Task definition references `…/coordinator_api:<promotion-tag>` |
| `docker compose up` pulls images and restarts containers | **Deploy** updates ECS services for a tenant/environment |

Each **tenant** or **environment** has a stack configuration (IaC template or manifest) listing journey services and the **promotion tag** each service uses — for example the `dev` tenant uses `:latest`, `test` uses `:test`, `conference` uses `:conference`.

That matches the mental model: *“Deploy the `test` configuration”* means *“Run the images currently tagged `test` and restart tasks.”*

---

### Deploy vs promote

Two separate automation actions:

| Action | What it does | Does not |
|--------|--------------|----------|
| **Promote** | Copy a **tag pointer** from one promotion tag to another in the registry (same digest, additional or moved tag). Example: images tagged `:production` also receive `:conference`. | Rebuild images. Does not by itself restart ECS (unless chained). |
| **Deploy** | For a target tenant/environment, resolve the configured promotion tag(s) to images, update ECS task definitions / services, and roll out (new tasks, drain old). | Rebuild images. |

```text
Promote (registry only):
  FROM tag :production  →  TO tag :conference
  (ECR: same manifest/digest gets a second tag, or tag is moved)

Deploy (runtime):
  tenant: conference
  config says: use tag :conference for all journey images
  → resolve :conference → digest(s)
  → register ECS task definition
  → ECS service rolling update
```

**Promote anywhere → anywhere (with guardrails):** Promotion is tag-to-tag in ECR (or GHCR mirror first, then ECR). The `from` and `to` tags are parameters — not a fixed pipeline only. Examples:

| Promote | Typical use |
|---------|-------------|
| `:latest` → `:test` | Dev integration passed; advance to QA tenant |
| `:test` → `:staging` | Release candidate to staging account |
| `:staging` → `:production` | Approved release to live (guarded) |
| `:production` → `:conference` | Stand up demo tenant with prod-known-good images |
| `:latest` → `:dev` | Alias sync after CI (if `dev` is distinct from `latest`) |

**Guardrails (target):**

| Transition | Guardrail |
|------------|-----------|
| Any → `dev` / `test` / `training` | Open to developers or SRE (low risk, dev account) |
| → `staging` | SRE or release manager; optional approval |
| → `production` | **Required approval** (GitHub Environment, manual workflow dispatch, or change ticket); audit log of digest set promoted |
| `production` → `conference` | Allowed for short-lived demos; uses `:conference` tag; **no prod data** — conference tenant in `mentorhub-dev` with its own database |
| `production` → `latest` / `test` | **Blocked** — prod must not overwrite dev promotion channels |

Conference deploy: promote `production` → `conference`, then **deploy** the `conference` tenant configuration (ECS stack pointing at `:conference`). Tear down tenant when the event ends.

---

### Design decision — tags for operators, digests for the running system

The README and earlier drafts emphasized **digest pinning** in ECS. That is **not** a different workflow from tag-based promote/deploy. It is an implementation detail at **deploy** time:

1. **Promote** uses tags (your model) — operators think in `:test`, `:staging`, `:conference`.
2. **Deploy** reads the tenant’s configured tag, **resolves tag → digest** at deploy time, and registers the task definition with that digest (or records digest in deploy metadata).

Why record digest if we use tags?

| Reason | Explanation |
|--------|-------------|
| **Reproducibility** | “What is running in prod?” is answered by digest, not by “whatever `:production` means today.” |
| **Race safety** | Between “start deploy” and “ECS pulls image,” someone could push a new image to `:production`. Resolving once at deploy start avoids half-updated fleets. |
| **Audit** | Change management and incident response need “exactly this build,” not “the tag we think we meant.” |
| **ECS best practice** | Task definitions should not rely on floating tags for production rollouts. |

So: **your compose-like tag configuration is the target UX.** Digest appears in the **deploy implementation** and in **audit trails**, not as something operators must type.

```text
Operator view:     promote production → conference ; deploy tenant conference
Automation view:   tag :conference → sha256:… ; ECS task def pins sha256:…
```

If the team later adopts **immutable tags** in ECR (e.g. `:production-20260702.1` never reused), digest pinning becomes less critical for prod — but promotion tags like `:conference` remain useful for tenant config.

---

### CI/CD flow (build → registry → promote → deploy)

```text
┌─────────────┐     merge main      ┌──────────────────┐
│ GitHub repo │ ──────────────────► │ GitHub Actions   │
└─────────────┘                     └────────┬─────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    ▼                      ▼                      ▼
            CodeArtifact              GHCR :latest            (tests)
            pip/npm deps            ghcr.io/mentor-forge/*
                    │                      │
                    │                      ▼
                    │               ECR mirror (same digest)
                    │                      │
                    └──────────┬───────────┘
                               ▼
              ┌────────────────────────────────────┐
              │  Promote workflow (tag → tag)       │
              │  e.g. :latest → :test              │
              │       :production → :conference    │
              └────────────────┬───────────────────┘
                               ▼
              ┌────────────────────────────────────┐
              │  Deploy workflow (per tenant/env)  │
              │  resolve tag → digest → ECS rollout│
              └────────────────┬───────────────────┘
                               ▼
         dev / test / training / conference / staging / production
```

### Automation examples

| Workflow | Type | Description |
|----------|------|-------------|
| CI on merge to `main` | Build | Push journey images to GHCR as `:latest`; mirror digest to ECR |
| `promote --from latest --to test` | Promote | Tag current `:latest` images as `:test` in ECR (no rebuild) |
| `deploy --tenant dev` | Deploy | Roll out ECS services for `dev` tenant using tag `:latest` (resolve to digest at deploy) |
| `promote --from staging --to production` | Promote | **Guarded** — after approval, tag staging digest set as `:production` |
| `deploy --tenant production` | Deploy | Roll out production ECS stack using `:production` |
| `promote --from production --to conference` | Promote | Demo prep — prod-known-good images get `:conference` tag |
| `deploy --tenant conference` | Deploy | Stand up conference tenant in `mentorhub-dev`; tear down after event |

GitHub Actions drive **promote** and **deploy** workflows (workflow_dispatch, environment approvals, or tag-push triggers). Implementation tasks: R030 (ECR), R100 (CD wiring).

---

## Findings for the Junior Architect

Items that are **incorrect, inconsistent, or risky** in the current design package. Fix these before treating `architecture.yaml` as implementation-ready.

### Must fix (correctness)

| # | Finding | Severity | Recommendation |
|---|---------|----------|----------------|
| F1 | Subnet names reference `us-east-2a` / `us-east-2b` but primary region is **`us-east-1`** | High | Rename subnets to `us-east-1a` / `us-east-1b` (or whichever AZs you actually use). AZ labels in names must match the deployment region. |
| F2 | Staging and production sections **copy-paste dev resource names** (`mentorhub-dev-cognito`, `mentorhub-dev-route53`, `mentorhub-dev-sns` for SES) | High | Each account gets its own resource names (`mentorhub-staging-cognito`, etc.). SES was labeled SNS — wrong service. |
| F3 | `mentorhub-dev` account ID is **TBD** in `config/aws-platform.yaml` and `parameters/dev.json` | High | Record the real account ID before any dev VPC/ECS deploy. Cross-account ECR pull and IAM trust policies depend on it. |
| F4 | Production `architecture.yaml` description says staging can "shut down between releases" — **copy-paste error** on production environment | Medium | Production is always-on. Fix the description. |

### Should fix (architecture gaps)

| # | Finding | Severity | Recommendation |
|---|---------|----------|----------------|
| F5 | **No cross-account ECR pull design** documented | High | ECS in workload accounts must pull from ECR in Shared-Services (`560167829275`). Document repository policies and/or pull-through cache; add to templates before R030/R060. |
| F6 | **Identity Center in `us-east-2`, workloads in `us-east-1`** | Low (valid) | Not wrong — Identity Center home region is chosen at enablement and is independent of workload region. Document this so interns do not "fix" it by collapsing regions. |
| F7 | **$100/month budgets** on all accounts including production | Medium | Fine as a dev-team alarm; not a capacity plan. Production needs a realistic budget and right-sizing after load testing. |
| F8 | **No WAF** on production edge | High (before go-live) | Add AWS WAF on API Gateway or CloudFront for prod. Dev can omit. |
| F9 | **No backup / restore runbook** for DocumentDB | High (before go-live) | Define retention, snapshot schedule, and restore test. DocumentDB supports automated backups — enable in template. |
| F10 | **No VPC endpoints** for ECR, S3, Secrets Manager | Medium | NAT Gateway charges per GB; interface endpoints reduce NAT traffic and improve security posture. Add when cost/ops reviewed. |
| F11 | **SPA hosting undecided** (ECS nginx vs S3 + CloudFront) | Medium | Decide in R070. Default recommendation: **S3 + CloudFront** for SPAs, ECS for APIs only. |
| F12 | **Tenant routing undecided** (hostname per tenant vs path prefix on shared host) | Medium | Path-based (`/coordinator/*`) is simpler with one cert; hostname-per-tenant (`dev.example.com`) mirrors prod more closely. Pick one for dev and document in templates. |
| F13 | **GitHub OIDC roles still manual**; placeholder CloudFormation template | Medium | Complete R031 — drift between console and IaC is already a risk for CodeArtifact roles. |
| F14 | **CIDR `TBD`** for staging and production VPCs | Medium | Plan non-overlapping CIDRs if future VPC peering or TGW is possible (e.g. `10.1.0.0/16`, `10.2.0.0/16`). |

### Acceptable but unusual (know the tradeoffs)

| Pattern | Why it's unusual | When it's OK here |
|---------|------------------|-------------------|
| Multi-tenant dev on shared DocumentDB | Production pattern would be account-per-tenant or cluster-per-tenant | Dev/test only; saves cost; team understands isolation is logical not physical |
| GHCR + ECR dual push | Most AWS-native shops use ECR only | Transitional while CI stays on GitHub; retire GHCR when ECR path is proven |
| Conference tenant runs **prod images** in **dev account** | Blurs environment boundaries | Short-lived demos with no prod data; tear down after event |
| ECS for everything including SPAs | SPAs are static files | Acceptable for pilot; revisit for cost and caching |
| API Gateway instead of ALB | ALB is more common for pure microservices | Gateway fits path-based multi-journey routing and future authorizers |
| DocumentDB instead of MongoDB Atlas | Second vendor can be simpler for small teams | In-VPC, IAM-integrated, one AWS bill — reasonable for this org size |
| Self-managed ELK + Prometheus on ECS | AWS-native path is OpenSearch + AMP + AMG | Valid for team learning and early volume; plan migration trigger (log GB/day, on-call load) |

---

## Deployment status (as of review)

| Component | Status |
|-----------|--------|
| Shared-Services account | Created |
| CodeArtifact domain + repos | Operational; CloudFormation import in progress (R020) |
| GitHub OIDC (CodeArtifact) | Operational (manual); codify in CFN (R031) |
| ECR + GHCR dual-push | In progress (R030) |
| mentorhub-dev account | Created; **no workload stacks deployed** |
| VPC, DocumentDB, ECS, API Gateway, Cognito | Templates scaffolded; not deployed |
| mentorhub-staging / production accounts | Not created |
| ELK (Elasticsearch, Logstash, Kibana) | Not started — target in Shared-Services |
| Prometheus + Grafana | Not started — target in Shared-Services |

See [config/aws-platform.yaml](./config/aws-platform.yaml) for canonical IDs and ARNs.

---

## Recommendations summary

**For interns — learn these patterns:**

1. Separate accounts by blast radius and lifecycle, not by "we might need it someday."
2. Build once, promote by tag — never rebuild for deploy; deploy resolves tag to digest for the running fleet.
3. Private subnets for workloads; public entry through a managed edge (API Gateway).
4. Platform services (registry, packages) live in a shared account; apps do not.
5. Dev cost controls (multi-tenant, shared cluster) are intentional; prod isolation is different on purpose.
6. Audit (CloudTrail), logs (ELK/Kibana), and metrics (Prometheus/Grafana) are three different systems — do not conflate them.

**For the Junior Architect — before staging/prod templates:**

1. Fix region/AZ naming and copy-paste errors in `architecture.yaml`.
2. Document cross-account ECR pull and implement in IaC.
3. Resolve SPA hosting and tenant routing (F11, F12).
4. Add production hardening checklist: WAF, DocumentDB backups, ELK/Grafana access control, realistic budgets.
5. Record all account IDs in `config/aws-platform.yaml`.
6. Design log pipeline (CloudWatch → ELK) and metrics labels for multi-tenant dev (F15–F19).

---

## Related documents

| Document | Purpose |
|----------|---------|
| [README.md](./README.md) | Platform overview (accounts, tenancy, CI/CD) — *what* |
| **ARCHITECTURE.md** (this file) | Design rationale and review — *why* and *what to fix* |
| [config/aws-platform.yaml](./config/aws-platform.yaml) | As-built configuration values |
| [docs/InfrastructureDiagram.svg](./docs/InfrastructureDiagram.svg) | Platform diagram (WIP) |
| [docs/ArchitectureDiagram.dev.svg](./docs/ArchitectureDiagram.dev.svg) | Cloud DEV runtime diagram (WIP) |
| [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) | Product journeys and repositories |
