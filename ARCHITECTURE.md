# MentorHub AWS Architecture — Solutions Architect Review

**Reviewer:** Senior AWS Solutions Architect (peer review)  
**Status:** Target architecture with partial deployment  
**Audience:** Interns (learn the *why*), Junior Architect (fix the gaps)  
**Companion docs:** [README.md](./README.md) (platform *what*), [config/aws-platform.yaml](./config/aws-platform.yaml) (as-built values), [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) (product journeys)

---

## Executive summary

MentorHub is a multi-journey web application (coordinator, mentor, mentee, customer) backed by MongoDB-shaped document data, deployed as containerized APIs and SPAs on **Amazon ECS**, with **DocumentDB** as the database, **Amazon Cognito** for identity, and an **Application Load Balancer (ALB)** as the public HTTPS edge. The platform uses a **multi-account AWS Organization**, separates **shared platform services** from **application workloads**, and promotes **immutable container images** from CI through dev → test → staging → production.

Account boundaries are intentional, the registry and package-management split is deliberate, and the dev-account multi-tenancy model controls cost without pretending to be production isolation.

---



## System context

```text
Developers (local Docker Compose)
        │
        ▼
GitHub (source) ──► GitHub Actions (CI)
        │                    │
        │                    ├──► CodeArtifact (pip/npm libs)
        │                    └──► ECR (container images, Shared-Services)
        │                              │
        ▼                              ▼
IAM Identity Center              ECS (per account/tenant)
(human access)                         │
                                       ├──► DocumentDB
                                       ├──► Cognito
                                       ├──► S3 / SES
                                       └──► Secrets Manager
        ▲
        └── ALB + Route 53 + ACM (+ WAF in prod) (public HTTPS)
```

**Product workloads:** eight journey repositories (four API + four SPA pairs), plus shared `api_utils` / `spa_utils` libraries, and `mongodb_api` configurator.

---



## Open source and third-party implementation

MentorHub is **open source in code**, not in **Mentor Forge’s operational pipeline**. GitHub is the source of truth for application repositories. We do **not** target public pre-built images (no public GHCR); images are built in CI and stored in **private ECR** for Mentor Forge deployments.

### Layers


| Layer                              | Open?                  | Notes                                                                                                                         |
| ---------------------------------- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Application source**             | Yes                    | Fork and modify under the project license.                                                                                    |
| **Shared libraries**               | Yes (source)           | `api-utils` / `spa_utils` published to **Mentor Forge CodeArtifact** for our CI — not a public package service for the world. |
| **Container images**               | No (public registry)   | Target: CI → **ECR** only. Third parties build and host their own images.                                                     |
| **This AWS platform**              | Yes (reference)        | CloudFormation, diagrams, and tasks document **how we run it**; adopters may copy ideas or ignore them.                       |
| **Mentor Forge CI secrets / OIDC** | Invited contributors   | Org secrets and CodeArtifact access require invitation — operational mote, not a license restriction.                         |
| **Minimal product trial (target)** | Hosted **demo** tenant | Public evaluators use a running environment in `mentorhub-dev` — not anonymous local container builds.                        |




### Third-party implementer path

External operators should assume **no supported shortcut**: fork repos, own dependency indexes, own registry, own IaC.

**Contributor local dev (target):** Invited developers use [Developer Edition](https://github.com/mentor-forge/mentorhub/tree/main/DeveloperEdition) (`mh`) with **IAM Identity Center** — **CodeArtifact** for `pipenv` / `npm ci` and local `docker build`, and **ECR** (Shared-Services) for pulling journey images in Compose. 

**As-built today (interim):** `mh pull` / `mh up` still call `ensureGhcrLogin` and pull `ghcr.io/mentor-forge/`* until R100 retires GHCR. Local image builds still require CodeArtifact (journey Dockerfiles and Pipfiles) — not an anonymous open-source path. **TODO:** Remove this paragraph when R100 is shipped.

**Minimal product trial (target):** A `demo` tenant in **mentorhub-dev** — a hosted, read-oriented environment (URL + demo personas) so evaluators can experience the product without building images or holding registry access. Serious self-hosters fork and implement their own pipeline.

Separating **OSS code** from **supported implementation** keeps mentor-forge team scope bounded, avoids paying for unbounded CodeArtifact/CI use, and still allows serious adopters to self-host with engineering investment. A hosted **demo** tenant avoids inventing an anonymous local-build path that fights the CodeArtifact and private-ECR model.

**Takeaway:** “Open source” here means you can read and fork the code — not that Mentor Forge will build, host, and ship containers for every deployment on the internet.

---



## Account model


| Account                  | Role                                                    | Why it exists                                                                                                                                        |
| ------------------------ | ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Management**           | Organization root, billing, Identity Center             | Keeps human identity and org governance out of workload accounts. Standard AWS best practice.                                                        |
| **Shared-Services**      | CodeArtifact, ECR, shared CloudTrail, GitHub OIDC roles | Platform services used by *all* environments but not tied to one app's lifecycle. Prevents "prod account owns the package registry" coupling.        |
| **mentorhub-dev**        | Multi-tenant dev / test / training / conference         | One account, many logical environments, shared VPC and DocumentDB cluster. Minimizes cost and operational overhead while the team is still building. |
| **mentorhub-staging**    | Single-tenant prod mirror                               | Validates releases in prod-like topology without prod blast radius. Designed to **scale down** between releases.                                     |
| **mentorhub-production** | Single-tenant live                                      | Customer-facing environment with stricter controls (HA, backups, WAF — to be implemented).                                                           |




### Account Decisions

**Multi-account** limits blast radius (a misconfigured dev experiment cannot delete the package registry), simplifies IAM (developers do not need prod power), and makes cost attribution possible per account.

**Shared-Services is not an app account.** Nothing that serves HTTP to end users runs there. If you see an ECS service proposed for Shared-Services, push back.

---



## Services by layer



### Identity and access


| Service                 | Where                    | Used for                                | Why                                                                                                 |
| ----------------------- | ------------------------ | --------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **IAM Identity Center** | Management (`us-east-2`) | Human login via SSO                     | No long-lived IAM users; permission sets map groups (Developer, SRE) to accounts.                   |
| **IAM OIDC (GitHub)**   | Shared-Services          | CI/CD authentication                    | GitHub Actions assumes short-lived roles to push to CodeArtifact and ECR — no access keys in repos. |
| **Amazon Cognito**      | Workload accounts        | End-user sign-in, JWTs for APIs         | Managed user pools; APIs validate tokens instead of implementing auth themselves.                   |
| **Secrets Manager**     | Workload accounts        | DB credentials, API keys, tenant config | Secrets are not baked into images; rotation is possible later.                                      |


**Key Decision:** OIDC for automation and Identity Center for humans. This is the modern baseline; IAM users with access keys in GitHub secrets is an anti-pattern we avoided.

---



### Build, registry, and delivery


| Service                  | Where           | Used for                                        | Why                                                                                                                                                  |
| ------------------------ | --------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **CodeArtifact**         | Shared-Services | Private PyPI and npm (`api-utils`, `spa_utils`) | Shared libraries are versioned packages, creating reproducible CI, faster builds, audit trail. Access is Mentor Forge–scoped (invited contributors). |
| **ECR**                  | Shared-Services | Authoritative container registry for ECS        | CI pushes images on merge to `main`. ECS tasks pull in-region.                                                                                       |
| **GitHub Actions**       | GitHub          | CI build and push                               | Build once on merge to `main`; OIDC to CodeArtifact and ECR. Org variables and role secrets in [docs/github-ci.md](./docs/github-ci.md).             |
| **Tag/deploy workflows** | GitHub + AWS    | CD promotion and rollout                        | **Promote** moves tags in ECR; **deploy** rolls ECS using tenant tag config.                                                                         |


**Promotion path:**

```text
merge main → build → ECR (:latest) → promote (tag → tag) → deploy (tenant/env ECS rollout)
```

**Core Rule:** Immutable images. CI builds once; promotion moves the **same image** through environments — we do not rebuild at deploy time.

**Core Rule:** ECR as the single registry for Mentor Forge runtime. Keeps images and pull policy inside AWS; aligns with the open-source boundary that external operators fork and publish their own images.

---



### Network and edge


| Service                    | Where                           | Used for                               | Why                                                                                                        |
| -------------------------- | ------------------------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **VPC**                    | Workload accounts               | Isolated network for ECS, DocumentDB   | Private subnets for workloads; public subnets for NAT and load-balanced entry. `10.0.0.0/16` in dev.       |
| **NAT Gateway**            | Workload VPC                    | Outbound internet from private subnets | ECS tasks in private subnets can reach external APIs (Stripe, etc.) without public IPs.                    |
| **ALB (Application Load Balancer)** | Workload VPC public subnets | Single HTTPS entry point               | Path- and host-based listener rules route to ECS target groups (journey SPAs and APIs). TLS termination, health checks, WAF attachment in prod. |
| **Route 53**               | Workload accounts               | DNS hostnames                          | Maps friendly names to the ALB (and to CloudFront if SPAs move to S3).                                     |
| **ACM**                    | Workload accounts               | TLS certificates                       | Free managed certs on the ALB listener (and CloudFront if used).                                          |
| **AWS WAF**                | Workload accounts (prod target) | Web application firewall               | Web ACL on the ALB in production — planned before go-live.                                                |


**Decision — ALB, not API Gateway:** Early docs named **API Gateway** (familiar from IBM API Connect / gateway products). For MentorHub on **ECS**, **ALB is the better fit**: listener rules already handle multi-journey path routing (`/coordinator`, `/mentor`, etc.); target groups map cleanly to one SPA + one API per journey; **ACM** and **WAF** attach directly to the ALB; no VPC Link or separate API proxy layer. **JWT validation stays in the Flask APIs** (`api_utils`) after Cognito issues tokens — we do not need API Gateway authorizers or usage plans at the edge. API Gateway remains a valid pattern for serverless or edge authorizers; it is not the target here.

**Key decision:** Internet-facing **ALB** in public subnets; **ECS tasks stay in private subnets** registered as target group targets. Operators get one hostname, path-based routing, and standard ECS observability (ALB access logs → OpenSearch).

#### ACM, WAF, and ALB — what they are and how we use them

**ACM (AWS Certificate Manager)** — AWS issues and auto-renews **TLS certificates** (the “padlock” for HTTPS). You prove domain ownership (usually via DNS in Route 53), and ACM handles renewal before expiry. **How we use it:** Attach an ACM certificate to the **ALB HTTPS listener** (and to **CloudFront** if SPAs move to S3 + CloudFront) so users reach `https://<app-hostname>` with a valid cert.

**WAF (AWS Web Application Firewall)** — A **layer-7 firewall** that inspects HTTP requests before they reach your app. Managed rule groups block SQL injection, cross-site scripting, known bad bots, and oversized payloads; you can add rate limits and geo rules. **How we use it:** Associate a WAF **web ACL** with the **production ALB** (or CloudFront if SPAs are served there). Dev and test can omit WAF to save cost; production should enable it before go-live (finding F8). WAF complements Cognito and API JWT checks — it filters malicious traffic, not “is this user logged in?”

**ALB (Application Load Balancer)** — A **regional load balancer** in the VPC that distributes HTTP/HTTPS to **target groups** (ECS services). It health-checks tasks, supports path/host/header routing, and integrates with ECS service connect patterns. **How we use it:** One **internet-facing ALB** per workload environment; listener rules send `/coordinator/*` (and similar) to the coordinator SPA and API target groups, `/api/*` paths to API services as defined in templates (see F12 for hostname vs path tenancy). This is the standard AWS pattern for containerized web apps and matches how nginx proxies in Developer Edition Compose.

**Open design choice (not yet resolved):** SPA static assets — serve from **ECS (nginx)** containers vs **S3 + CloudFront**. ECS works for parity with local dev; S3 + CloudFront is usually cheaper and more scalable for static files. Decide before R070/R090 implementation.

---



### Compute and data


| Service            | Where             | Used for                                     | Why                                                                                                                                 |
| ------------------ | ----------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **ECS on Fargate** | Workload accounts | Run API and SPA containers                   | No EC2 fleet to patch; pay per task; fits small team's ops capacity.                                                                |
| **DocumentDB**     | Workload accounts | MongoDB-compatible document store            | Product uses MongoDB APIs (`mongodb_api` configurator, Flask + mongo drivers). DocumentDB is AWS-managed with backups and patching. |
| **S3**             | Workload accounts | Object storage (uploads, exports, artifacts) | Durable, cheap storage decoupled from container lifecycle.                                                                          |
| **SES**            | Workload accounts | Transactional email                          | Password reset, notifications. Sandbox in dev; production access requires AWS approval.                                             |


**Good decision:** DocumentDB for a MongoDB-shaped product on AWS. Running self-managed MongoDB on EC2 would burden a small SRE team. Atlas is a valid alternative but adds a second vendor and network path; DocumentDB keeps data in-VPC with IAM and CloudTrail integration.

**Dev multi-tenancy model:** One DocumentDB **cluster**, separate **database** per tenant (`mentorhub-dev`, `mentorhub-test`, etc.). Collections are never shared across tenants.


| Tenant       | Typical use                                             |
| ------------ | ------------------------------------------------------- |
| `dev`        | Daily integration; receives `:latest`                   |
| `test`       | QA / automated acceptance                               |
| `training`   | Workshops and onboarding                                |
| `conference` | Short-lived demo environment (may promote prod digests) |


**Why share a cluster in dev:** Cost. A DocumentDB cluster has a minimum hourly charge. Four clusters for four tenants would multiply cost without improving dev fidelity. Logical isolation by database name is sufficient for non-production **if** connection strings and secrets are tenant-scoped and access controls are enforced in application config.

**Not acceptable for production:** Production must be single-tenant with its own cluster, backups, and monitoring — which the target architecture already specifies.

---



### Observability and governance

Observability is **layered**: AWS-native services for collection and audit, **Amazon OpenSearch Service** for log search and analysis, **Prometheus + Grafana** for metrics and dashboards.

```text
Application / ECS tasks
        │
        ├──► CloudWatch Logs (ECS default log driver)
        │         │
        │         └──► Fluent Bit / subscription filter ──► OpenSearch (managed)
        │                                                      └──► OpenSearch Dashboards
        │
        └──► Prometheus (scrape or ADOT collector) ──► Grafana (dashboards + alerts)

AWS API activity ──► CloudTrail (all accounts)     ← audit, not application logs
AWS service metrics ──► CloudWatch Metrics          ← optional Grafana datasource
```



#### AWS platform layer (all accounts)


| Service             | Where             | Used for                                        | Why                                                                                                               |
| ------------------- | ----------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **CloudTrail**      | All accounts      | API audit log                                   | Who changed infrastructure in AWS; compliance and security investigations. Not a substitute for application logs. |
| **CloudWatch Logs** | Workload accounts | ECS task stdout/stderr, ALB access logs | Native ECS log driver (`awslogs`); ALB logs optional to S3/OpenSearch; required collection point before forwarding application logs to OpenSearch. |
| **CloudFormation**  | All accounts      | Infrastructure as code                          | Reproducible stacks, change sets, import for existing resources (CodeArtifact).                                   |
| **AWS Budgets**     | All accounts      | Cost alerts                                     | Early warning before surprise bills.                                                                              |




#### Log analytics — Amazon OpenSearch Service (decided)

**Decision:** Use **Amazon OpenSearch Service** (managed) instead of a self-managed ELK stack on ECS. OpenSearch is the AWS-managed evolution of the Elasticsearch API; **OpenSearch Dashboards** replaces Kibana for log exploration.


| Component                                    | Used for                           | Why                                                                                                                       |
| -------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Amazon OpenSearch Service**                | Log storage and full-text search   | Managed cluster (patching, scaling, snapshots); Elasticsearch-compatible query DSL; no Logstash/Elasticsearch ops on ECS. |
| **OpenSearch Dashboards**                    | Log exploration and visualisations | Built-in UI for OpenSearch; same role Kibana played in ELK — search, filters, dashboards.                                 |
| **Fluent Bit** (or **OpenSearch Ingestion**) | Log shipping and enrichment        | Forward from CloudWatch Logs or ECS; add `tenant`, `environment`, `service`, `journey` fields for multi-tenant dev.       |


**Why not self-managed ELK:** A small SRE team should not operate Elasticsearch, Logstash, and Kibana on ECS alongside application workloads. Managed OpenSearch reduces on-call burden, integrates with VPC and IAM, and stays on one AWS bill. The team still learns portable log-query concepts (index patterns, field filters, aggregations) without running the data plane.

**Placement:** Shared-Services account — one OpenSearch domain serves dev, staging, and production log indices (separate index prefixes or ISM policies per environment/tenant). Workload accounts forward via CloudWatch Logs subscription filters or Fluent Bit.

**Intern takeaway:** CloudTrail tells you *who deleted a security group*. OpenSearch Dashboards tells you *why the coordinator API returned 500 at 2am*.

#### Metrics and dashboards — Prometheus + Grafana (target)


| Component      | Used for                                                             | Why                                                                                                                                                |
| -------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Prometheus** | Time-series metrics (request rate, latency, errors, ECS task health) | Pull-based metrics model fits containers; PromQL is portable; integrates with alert routing.                                                       |
| **Grafana**    | Dashboards, alerting, on-call views                                  | Single pane for journey health, tenant comparison, and infra metrics; can add CloudWatch as a secondary datasource for DocumentDB/ECS AWS metrics. |




#### Application metrics — `/metrics` on every API (implemented)

All journey domain APIs follow [API Standards](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/api_standards.md): each Flask service calls `api_utils.create_metric_routes(app)` (`prometheus-flask-exporter` middleware) in `server.py`. That exposes `GET /metrics` in Prometheus text exposition format — no blueprint registration, no JWT (scrapers must reach the container, not the authenticated `/api/*` surface).


| What                  | Detail                                                                                                                                                                                                  |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Standard**          | Required on every API alongside `/api/config` and `/docs/`* — see [api_utils](https://github.com/mentor-forge/mentorhub_api_utils/blob/main/api_utils/routes/metric_routes.py) `create_metric_routes()` |
| **Metrics emitted**   | HTTP request counts, durations (histogram), status codes, active requests — labelled by method, path, and status                                                                                        |
| **Domain APIs today** | coordinator, customer, mentee, mentor (and `api_utils` demo server)                                                                                                                                     |
| **Local check**       | `curl http://localhost:<api-port>/metrics` (port per service; demo server uses `9092`)                                                                                                                  |


**What Prometheus scrapes (target):**

1. **Application** — each ECS task’s API container at `http://<task-ip>:<api-port>/metrics` (private subnet; not via the ALB).
2. **Platform** — ALB, ECS, DocumentDB via CloudWatch (optional Grafana datasource) or ADOT exporters where needed.

Prometheus in Shared-Services (or a cluster-local scraper forwarding to it) discovers ECS tasks and pulls `/metrics` on a short interval. Grafana dashboards aggregate per-service and per-tenant views once scrape targets carry `tenant`, `environment`, `service`, and `journey` labels (F17).

**Placement:** Shared-Services alongside OpenSearch, or co-located on the same ECS cluster dedicated to platform tooling.

#### Good decisions

- **Separate concerns:** CloudTrail (audit) ≠ OpenSearch (application logs) ≠ Prometheus (metrics). Mixing them creates noisy dashboards and wrong retention policies.
- **Centralise observability tooling** in Shared-Services so dev tenants and future staging/prod feed one OpenSearch domain and one Grafana — operators do not context-switch per account.
- **Standard** `/metrics` **on every API:** Application metrics are already implemented via `api_utils`; platform work is wiring Prometheus scrape targets and Grafana dashboards, not adding per-service exporters.
- **Managed OpenSearch + self-managed Prometheus/Grafana (initially):** Logs benefit most from a managed service at our scale; metrics tooling may later move to Amazon Managed Prometheus / Amazon Managed Grafana if ops burden grows.
- **OpenSearch over self-managed ELK:** Same search UX family without operating Elasticsearch and Logstash on ECS.



#### Findings for observability (Junior Architect)


| #   | Finding                                                       | Recommendation                                                                                                                                                                               |
| --- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| F15 | OpenSearch not yet in templates or `config/aws-platform.yaml` | Add OpenSearch domain + Dashboards access to IaC backlog (Shared-Services); size for dev volume with scale-up path.                                                                          |
| F16 | No log pipeline design (CloudWatch → OpenSearch)              | Document in templates: Fluent Bit sidecar vs CloudWatch Logs subscription → OpenSearch Ingestion / direct indexing.                                                                          |
| F17 | No tenant/env labels on logs and metrics                      | Require `tenant`, `environment`, `service`, `journey` labels on ECS scrape targets and log fields; application `/metrics` already expose method/path/status via `prometheus-flask-exporter`. |
| F18 | Prometheus HA and retention not defined                       | For prod: two Prometheus replicas or Amazon Managed Prometheus; define retention (e.g. 15d metrics, 30d logs in OpenSearch ISM).                                                             |
| F19 | Dashboards and Grafana auth not defined                       | Integrate OpenSearch Dashboards and Grafana with Cognito or Identity Center SSO; do not expose either on the public internet.                                                                |


**Good decision:** Importing existing CodeArtifact into CloudFormation instead of delete-and-recreate. CodeArtifact domains are stateful; recreation would break every consumer pipeline.

---



## Environment strategy


| Environment                        | Account              | Tenancy              | Fidelity                                       |
| ---------------------------------- | -------------------- | -------------------- | ---------------------------------------------- |
| Local                              | Developer machine    | Single Compose stack | Fast feedback; MailHog instead of SES.         |
| Dev / Test / Training / Conference | mentorhub-dev        | Multi-tenant         | Shared infra; separate DB and config.          |
| Staging                            | mentorhub-staging    | Single tenant        | Prod topology; may power off between releases. |
| Production                         | mentorhub-production | Single tenant        | Live customers.                                |


**Good decision:** Staging as a **prod mirror that can sleep**. Staging that runs 24/7 often costs nearly as much as prod while providing little extra value for a release cadence measured in weeks, not hours.

**Good decision:** Conference as a **short-lived tenant in dev**, not a fifth account. Demos need prod-like data and images without prod risk or prod cost.

---



## CI/CD and change management



### Tags vs digests — what interns should know

A container **image** is the built artifact (layers + manifest). Registries refer to it in two ways:


| Concept    | Example                                                      | Mutable?           | What it means                                                                       |
| ---------- | ------------------------------------------------------------ | ------------------ | ----------------------------------------------------------------------------------- |
| **Tag**    | `:latest`, `:test`, `:staging`, `:production`, `:conference` | **Yes** (floating) | A label pointing at an image. The same tag can be moved to a newer build later.     |
| **Digest** | `sha256:abc123…`                                             | **No**             | A fingerprint of the exact image bytes. Same digest always means identical content. |


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


| Local (Compose)                                          | Cloud (ECS)                                                        |
| -------------------------------------------------------- | ------------------------------------------------------------------ |
| `image: <local build or compose service name>`           | Task definition references ECR `…/coordinator_api:<promotion-tag>` |
| `docker compose up` pulls images and restarts containers | **Deploy** updates ECS services for a tenant/environment           |


Each **tenant** or **environment** has a stack configuration (IaC template or manifest) listing journey services and the **promotion tag** each service uses — for example the `dev` tenant uses `:latest`, `test` uses `:test`, `conference` uses `:conference`.

That matches the mental model: *“Deploy the* `test` *configuration”* means *“Run the images currently tagged* `test` *and restart tasks.”*

---



### Deploy vs promote

Two separate automation actions:


| Action      | What it does                                                                                                                                                                      | Does not                                                         |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **Promote** | Copy a **tag pointer** from one promotion tag to another in the registry (same digest, additional or moved tag). Example: images tagged `:production` also receive `:conference`. | Rebuild images. Does not by itself restart ECS (unless chained). |
| **Deploy**  | For a target tenant/environment, resolve the configured promotion tag(s) to images, update ECS task definitions / services, and roll out (new tasks, drain old).                  | Rebuild images.                                                  |


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

**Promote anywhere → anywhere (with guardrails):** Promotion is tag-to-tag in **ECR**. The `from` and `to` tags are parameters — not a fixed pipeline only. Examples:


| Promote                       | Typical use                                              |
| ----------------------------- | -------------------------------------------------------- |
| `:latest` → `:test`           | Dev integration passed; advance to QA tenant             |
| `:test` → `:staging`          | Release candidate to staging account                     |
| `:staging` → `:production`    | Approved release to live (guarded)                       |
| `:production` → `:conference` | Stand up demo tenant with prod-known-good images         |
| `:latest` → `:dev`            | Alias sync after CI (if `dev` is distinct from `latest`) |


**Guardrails (target):**


| Transition                        | Guardrail                                                                                                                            |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Any → `dev` / `test` / `training` | Open to developers or SRE (low risk, dev account)                                                                                    |
| → `staging`                       | SRE or release manager; optional approval                                                                                            |
| → `production`                    | **Required approval** (GitHub Environment, manual workflow dispatch, or change ticket); audit log of digest set promoted             |
| `production` → `conference`       | Allowed for short-lived demos; uses `:conference` tag; **no prod data** — conference tenant in `mentorhub-dev` with its own database |
| `production` → `latest` / `test`  | **Blocked** — prod must not overwrite dev promotion channels                                                                         |


Conference deploy: promote `production` → `conference`, then **deploy** the `conference` tenant configuration (ECS stack pointing at `:conference`). Tear down tenant when the event ends.

---



### Design decision — tags for operators, digests for the running system

The README and earlier drafts emphasized **digest pinning** in ECS. That is **not** a different workflow from tag-based promote/deploy. It is an implementation detail at **deploy** time:

1. **Promote** uses tags (your model) — operators think in `:test`, `:staging`, `:conference`.
2. **Deploy** reads the tenant’s configured tag, **resolves tag → digest** at deploy time, and registers the task definition with that digest (or records digest in deploy metadata).

Why record digest if we use tags?


| Reason                | Explanation                                                                                                                                               |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Reproducibility**   | “What is running in prod?” is answered by digest, not by “whatever `:production` means today.”                                                            |
| **Race safety**       | Between “start deploy” and “ECS pulls image,” someone could push a new image to `:production`. Resolving once at deploy start avoids half-updated fleets. |
| **Audit**             | Change management and incident response need “exactly this build,” not “the tag we think we meant.”                                                       |
| **ECS best practice** | Task definitions should not rely on floating tags for production rollouts.                                                                                |


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
            CodeArtifact              ECR :latest              (tests)
            pip/npm deps            Shared-Services
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


| Workflow                                    | Type    | Description                                                                              |
| ------------------------------------------- | ------- | ---------------------------------------------------------------------------------------- |
| CI on merge to `main`                       | Build   | Push journey images to ECR as `:latest`                                                  |
| `promote --from latest --to test`           | Promote | Tag current `:latest` images as `:test` in ECR (no rebuild)                              |
| `deploy --tenant dev`                       | Deploy  | Roll out ECS services for `dev` tenant using tag `:latest` (resolve to digest at deploy) |
| `promote --from staging --to production`    | Promote | **Guarded** — after approval, tag staging digest set as `:production`                    |
| `deploy --tenant production`                | Deploy  | Roll out production ECS stack using `:production`                                        |
| `promote --from production --to conference` | Promote | Demo prep — prod-known-good images get `:conference` tag                                 |
| `deploy --tenant conference`                | Deploy  | Stand up conference tenant in `mentorhub-dev`; tear down after event                     |


GitHub Actions drive **promote** and **deploy** workflows (workflow_dispatch, environment approvals, or tag-push triggers). Implementation tasks: R030 (ECR), R100 (CD wiring).

**CI configuration:** Organization variables (`AWS_REGION`, CodeArtifact names), org secrets (`AWS_ROLE_ARN_READ`, `AWS_ROLE_ARN_PUBLISH`), workflow patterns per repo type, and Dockerfile auth patterns are documented in [docs/github-ci.md](./docs/github-ci.md).

---



## Findings for the Junior Architect

Items that are **incorrect, inconsistent, or risky** in the current design package. Fix these before treating `architecture.yaml` as implementation-ready.

### Must fix (correctness)


| #   | Finding                                                                                                                                           | Severity | Recommendation                                                                                                                          |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| F1  | Subnet names reference `us-east-2a` / `us-east-2b` but primary region is `us-east-1`                                                              | High     | Rename subnets to `us-east-1a` / `us-east-1b` (or whichever AZs you actually use). AZ labels in names must match the deployment region. |
| F2  | Staging and production sections **copy-paste dev resource names** (`mentorhub-dev-cognito`, `mentorhub-dev-route53`, `mentorhub-dev-sns` for SES) | High     | Each account gets its own resource names (`mentorhub-staging-cognito`, etc.). SES was labeled SNS — wrong service.                      |
| F3  | `mentorhub-dev` account ID is **TBD** in `config/aws-platform.yaml` and `parameters/dev.json`                                                     | High     | Record the real account ID before any dev VPC/ECS deploy. Cross-account ECR pull and IAM trust policies depend on it.                   |
| F4  | Production `architecture.yaml` description says staging can "shut down between releases" — **copy-paste error** on production environment         | Medium   | Production is always-on. Fix the description.                                                                                           |




### Should fix (architecture gaps)


| #   | Finding                                                                          | Severity              | Recommendation                                                                                                                                                              |
| --- | -------------------------------------------------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| F5  | **No cross-account ECR pull design** documented                                  | High                  | ECS in workload accounts must pull from ECR in Shared-Services (`560167829275`). Document repository policies and/or pull-through cache; add to templates before R030/R060. |
| F6  | **Identity Center in** `us-east-2`**, workloads in** `us-east-1`                 | Low (valid)           | Not wrong — Identity Center home region is chosen at enablement and is independent of workload region. Document this so interns do not "fix" it by collapsing regions.      |
| F7  | **$100/month budgets** on all accounts including production                      | Medium                | Fine as a dev-team alarm; not a capacity plan. Production needs a realistic budget and right-sizing after load testing.                                                     |
| F8  | **No WAF** on production edge                                                    | High (before go-live) | Add AWS WAF web ACL on the production **ALB** (or CloudFront if SPAs move to S3). Dev can omit.                                                                               |
| F9  | **No backup / restore runbook** for DocumentDB                                   | High (before go-live) | Define retention, snapshot schedule, and restore test. DocumentDB supports automated backups — enable in template.                                                          |
| F10 | **No VPC endpoints** for ECR, S3, Secrets Manager                                | Medium                | NAT Gateway charges per GB; interface endpoints reduce NAT traffic and improve security posture. Add when cost/ops reviewed.                                                |
| F11 | **SPA hosting undecided** (ECS nginx vs S3 + CloudFront)                         | Medium                | Decide in R070. Default recommendation: **S3 + CloudFront** for SPAs, ECS for APIs only.                                                                                    |
| F12 | **Tenant routing undecided** (hostname per tenant vs path prefix on shared host) | Medium                | ALB supports both (host-based vs path-based listener rules). Path-based (`/coordinator/*`) is simpler with one cert; hostname-per-tenant mirrors prod more closely. Pick one for dev and document in templates. |
| F13 | **GitHub OIDC roles still manual**; placeholder CloudFormation template          | Medium                | Complete R031 — drift between console and IaC is already a risk for CodeArtifact roles.                                                                                     |
| F14 | **CIDR** `TBD` for staging and production VPCs                                   | Medium                | Plan non-overlapping CIDRs if future VPC peering or TGW is possible (e.g. `10.1.0.0/16`, `10.2.0.0/16`).                                                                    |




### Acceptable but unusual (know the tradeoffs)


| Pattern                                                   | Why it's unusual                                                     | When it's OK here                                                                                          |
| --------------------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Multi-tenant dev on shared DocumentDB                     | Production pattern would be account-per-tenant or cluster-per-tenant | Dev/test only; saves cost; team understands isolation is logical not physical                              |
| No public container registry                              | Many OSS projects publish Docker Hub / GHCR images                   | Intentional — third parties fork and build; see [Open source](#open-source-and-third-party-implementation) |
| Conference tenant runs **prod images** in **dev account** | Blurs environment boundaries                                         | Short-lived demos with no prod data; tear down after event                                                 |
| ECS for everything including SPAs                         | SPAs are static files                                                | Acceptable for pilot; revisit S3 + CloudFront for cost and caching (F11)                                   |
| DocumentDB instead of MongoDB Atlas                       | Second vendor can be simpler for small teams                         | In-VPC, IAM-integrated, one AWS bill — reasonable for this org size                                        |
| Self-managed Prometheus + Grafana on ECS                  | AWS-native path is AMP + AMG                                         | Acceptable initially; revisit when on-call load grows                                                      |


---



## Deployment status (as of review)


| Component                                  | Status                                                |
| ------------------------------------------ | ----------------------------------------------------- |
| Shared-Services account                    | Created                                               |
| CodeArtifact domain + repos                | Operational; CloudFormation import in progress (R020) |
| GitHub OIDC (CodeArtifact)                 | Operational (manual); codify in CFN (R031)            |
| ECR (CI push target)                       | In progress (R030)                                    |
| mentorhub-dev account                      | Created; **no workload stacks deployed**              |
| VPC, DocumentDB, ECS, ALB, Cognito | Templates scaffolded; not deployed (`templates/dev/api-gateway.yaml` placeholder to be replaced with ALB stack in R070) |
| mentorhub-staging / production accounts    | Not created                                           |
| Amazon OpenSearch Service + Dashboards     | Not started — target in Shared-Services               |
| Prometheus + Grafana                       | Not started — target in Shared-Services               |


See [config/aws-platform.yaml](./config/aws-platform.yaml) for canonical IDs and ARNs.

---



## Recommendations summary

**For interns — learn these patterns:**

1. Separate accounts by blast radius and lifecycle, not by "we might need it someday."
2. Build once, promote by tag — never rebuild for deploy; deploy resolves tag to digest for the running fleet.
3. Private subnets for workloads; public entry through **ALB** (TLS + routing), not internet-facing tasks.
4. Platform services (registry, packages) live in a shared account; apps do not.
5. Dev cost controls (multi-tenant, shared cluster) are intentional; prod isolation is different on purpose.
6. Audit (CloudTrail), logs (OpenSearch Dashboards), and metrics (Prometheus/Grafana) are three different systems — do not conflate them.

**For the Junior Architect — before staging/prod templates:**

1. Fix region/AZ naming and copy-paste errors in `architecture.yaml`.
2. Document cross-account ECR pull and implement in IaC.
3. Resolve SPA hosting and tenant routing (F11, F12).
4. Add production hardening checklist: WAF, DocumentDB backups, OpenSearch/Grafana access control, realistic budgets.
5. Record all account IDs in `config/aws-platform.yaml`.
6. Design log pipeline (CloudWatch → OpenSearch) and metrics labels for multi-tenant dev (F15–F19).

---



## Related documents


| Document                                                                                                                           | Purpose                                               |
| ---------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| [README.md](./README.md)                                                                                                           | Platform overview (accounts, tenancy, CI/CD) — *what* |
| **ARCHITECTURE.md** (this file)                                                                                                    | Design rationale and review — *why* and *what to fix* |
| [config/aws-platform.yaml](./config/aws-platform.yaml)                                                                             | As-built configuration values                         |
| [docs/github-ci.md](./docs/github-ci.md)                                                                                           | GitHub org variables, secrets, CI workflows           |
| [docs/InfrastructureDiagram.svg](./docs/InfrastructureDiagram.svg)                                                                 | Platform diagram (WIP)                                |
| [docs/ArchitectureDiagram.dev.svg](./docs/ArchitectureDiagram.dev.svg)                                                             | Cloud DEV runtime diagram (WIP)                       |
| [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) | Product journeys and repositories                     |


