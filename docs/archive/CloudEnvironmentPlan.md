# Cloud Environment Plan

Platform and runtime scope for MentorHub across Local, Dev, Staging, and Production. Complements [architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml), [aws-platform.yaml](./aws-platform.yaml), [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md), and [sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md).

**Status:** Active (refreshed 2026-06-25)  
**Primary region:** `us-east-1`  
**First workload account:** `MentorHub-Dev`  
**Integrated critical path:** [LiveDevPlan.md](./LiveDevPlan.md) · **Executable tasks:** [tasks/README.md](../../tasks/README.md)

---

## Environment model

| Environment | AWS account | Diagram | Runtime status |
|-------------|-------------|---------|----------------|
| Local | Developer machine (Docker Desktop) | [ArchitectureDiagram.local.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.local.svg) | **Complete** |
| Development | `MentorHub-Dev` (account ID TBD — [D-1](./CLOUDFORMATION_PLAN.md#7-open-decisions)) | [ArchitectureDiagram.dev.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.svg) | **Not deployed** — templates scaffolded; diagram WIP |
| Staging | TBD (separate account or shared) | *Not created* | Not started (R120) |
| Production | TBD | *Not created* | Not started (R130) |

**Platform services** (not application workloads) live in **`Shared-Services`** (`560167829275`): CodeArtifact, GitHub OIDC roles, ECR (in progress), shared CloudTrail (pending R031).

---

## As-built vs target (AWS Organization)

### As-built today (2026-06-25)

```text
AWS Organization
└── Root
    ├── Management account (Mike Storey)
    ├── Shared-Services (560167829275)   ← CodeArtifact operational
    └── MentorHub-Dev (development workload)
```

Done:

- [x] IAM Identity Center enabled (`us-east-2`)
- [x] Primary workload region recorded (`us-east-1`)
- [x] `Shared-Services` account created (`560167829275`)
- [x] `Developer-Packages` permission set on Shared-Services for `Developer` group
- [x] CodeArtifact domain `mentor-forge` + repos `mentorhub-pypi`, `mentorhub-npm` ([INFO.md](./INFO.md))
- [x] GitHub OIDC roles for CodeArtifact publish/read (manual; consumers working)
- [x] Utils published to CodeArtifact; all eight consumer APIs/SPAs migrated off git deps ([DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) Phase 2–3)
- [x] `mh` CodeArtifact auth + Developer Edition docs updated ([mentorhub PR #18](https://github.com/mentor-forge/mentorhub/pull/18))
- [x] CloudTrail on MentorHub-Dev (`mentorhub-dev-trail`)
- [x] Budget on MentorHub-Dev ($50 / month)
- [x] CI publishes containers to GHCR on merge to `main`
- [x] IaC repo bootstrapped ([R010](../../tasks/SHIPPED.R010.repo_bootstrap.md)); templates scaffolded

In progress:

- [ ] CodeArtifact under CloudFormation ([R020](../../tasks/RUNNING.R020.codeartifact_import.md) — import template merged; execute pending SRE)
- [ ] ECR repos + GHCR ↔ ECR dual-push ([R030](../../tasks/RUNNING.R030.ecr_ghcr_connection.md) — **Now**)
- [ ] Shared-Services CloudTrail + budget + OIDC codified in CF ([R031](../../tasks/PENDING.R031.shared_services_cloudtrail_budget.md))

Not started:

- [ ] MentorHub-Dev application runtime (VPC, DocumentDB, ECS, public URL) — R040+
- [ ] MentorHub-Dev account ID recorded in `parameters/dev.json` and aws-platform.yaml

### Target before first cloud deploy

Same org shape as as-built. Remaining gap is **workload infrastructure and app runtime** in MentorHub-Dev, not org accounts.

```text
AWS Organization
└── Root
    ├── Management
    ├── Shared-Services      ← CodeArtifact ✓, ECR ◐, CF governance ◐
    └── MentorHub-Dev        ← ECS, DocumentDB, gateway, Cognito (not deployed)
```

---

## Phase 0 — Platform foundation (Shared-Services)

**Owner:** SRE (Luther / Lucky)  
**Blocks:** Reproducible builds without git-based utils deps  
**Detail:** [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) Phase -1 and Phase 0  
**CF tasks:** R020, R030, R031

| ID | Task | Done | Notes |
|----|------|------|-------|
| P0-1 | Create `Shared-Services` AWS account | [x] | `560167829275` |
| P0-2 | Budget ($25) + CloudTrail on Shared-Services | [ ] | [R031](../../tasks/PENDING.R031.shared_services_cloudtrail_budget.md) |
| P0-3 | Create `Developer-Packages` permission set; assign `Developer` group | [x] | Validated via consumer `mh` / npm ci |
| P0-4 | Record `AWS_SHARED_SERVICES_ACCOUNT_ID` in [aws-platform.yaml](./aws-platform.yaml) and GitHub org variables | [x] | |
| P0-5 | Create CodeArtifact domain `mentor-forge` + repos `mentorhub-pypi`, `mentorhub-npm` | [x] | [INFO.md](./INFO.md); CF import [R020](../../tasks/RUNNING.R020.codeartifact_import.md) |
| P0-6 | GitHub OIDC roles: `GitHubActionsCodeArtifactPublish`, `GitHubActionsCodeArtifactRead` | [x] | Live manually; codify in CF via R031 |
| P0-7 | Publish pipelines for `mentorhub_api_utils` and `mentorhub_spa_utils` | [x] | Packages on CodeArtifact |
| P0-8 | Migrate consumer APIs/SPAs off git deps; implement `mh codeartifact login` | [x] | [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) Phase 2–3 complete |
| P0-9 | Revise [sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md) to match as-built | [~] | Onboarding/docs updated; full IaC alignment in [R110](../../tasks/PENDING.R110.documentation_hygiene.md) |

**Exit criteria:** Developer runs `pipenv install` / `npm ci` using CodeArtifact only; no `GH_PAT` for utils in Docker builds. **Met** for consumer repos; Phase 5 cleanup (remove legacy git paths from Dockerfiles) still in progress per DEPENDENCY_MOVE.

**Remaining Phase 0 work (IaC):** R020 import execute → R030 ECR + dual-push → R031 Shared governance codified.

---

## Phase 1 — Cloud DEV infrastructure (MentorHub-Dev)

**Owner:** SRE  
**Blocks:** Running MentorHub in AWS (fundraising campaign 3: “cloud for dev”)  
**Diagram guide:** [ArchitectureDiagram.dev.guide.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.guide.md)  
**CF tasks:** R040 → R050 → R060 → R070 → R080 (Milestone A); R090, R100, R110 (Milestone B)

**Status:** Templates scaffolded in `templates/dev/`; **no stacks deployed**. See [LiveDevPlan.md](./LiveDevPlan.md) for stack deploy order.

### 1.1 Networking — [R040](../../tasks/PENDING.R040.dev_governance_network.md)

| ID | Task | Done | Diagram box |
|----|------|------|-------------|
| D1-1 | Design VPC CIDR and AZ layout | [x] | Environment callout — `10.0.0.0/16` in `parameters/dev.json` |
| D1-2 | **Public subnets** — ALB / API Gateway endpoints | [ ] | Rename `VPC1` → Public subnets |
| D1-3 | **Private subnets** — ECS tasks, DocumentDB | [ ] | Rename `VPC 2` → Private subnets |
| D1-4 | NAT gateway(s) for private egress | [ ] | Add to diagram if not shown |
| D1-5 | Security groups: gateway → ECS → DocumentDB | [ ] | Document on diagram edges |
| D1-6 | Decide developer access: SSO only vs Client VPN | [ ] | [D-6](./CLOUDFORMATION_PLAN.md#7-open-decisions) — blocks R040 |

### 1.2 Data — [R050](../../tasks/PENDING.R050.dev_data_secrets.md)

| ID | Task | Done | Diagram box |
|----|------|------|-------------|
| D1-7 | DocumentDB cluster (MongoDB 7 compatible) | [ ] | AWS DocumentDB |
| D1-8 | Secrets Manager: connection string, `JWT_SECRET` | [ ] | Edge ECS → DocumentDB |
| D1-9 | Run `mongodb_api` configure job once (schema + test data policy) | [ ] | mongodb_api service — at [R080](../../tasks/PENDING.R080.pilot_coordinator.md) |

### 1.3 Compute and images — [R030](../../tasks/RUNNING.R030.ecr_ghcr_connection.md), [R060](../../tasks/PENDING.R060.dev_compute_platform.md), [R080](../../tasks/PENDING.R080.pilot_coordinator.md)–[R090](../../tasks/PENDING.R090.remaining_dev_services.md)

| ID | Task | Done | Diagram box |
|----|------|------|-------------|
| D1-10 | ECR repositories | [~] | R030 in progress; GHCR interim until ECR proven |
| D1-11 | ECS cluster + Fargate task definitions per service | [ ] | AWS ECS |
| D1-12 | Map 8 API + 8 SPA containers from [architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) | [ ] | All `*_api` / `*_spa` boxes — pilot at R080, full at R090 |
| D1-13 | NGINX SPA containers proxy `/api/*` to paired API (see sre_standards) | [ ] | SPA → API edges |

**Service inventory (cloud DEV):**

| Service | Port (local ref) | Data domains |
|---------|------------------|--------------|
| mongodb_api | 8383 | Schema configure (ops job, not user-facing) |
| coordinator_api / spa | 8389 / 8390 | Customer, Identity, Profile, Login |
| customer_api / spa | 8387 / 8388 | Subscription, Dashboard, Card + consumes |
| mentor_api / spa | 8391 / 8392 | Resource, Path, Plan, Encounter |
| mentee_api / spa | 8393 / 8394 | Journey, Rating, Note |
| runbook_api | 8395 | Runbook automation (add to diagram) |

### 1.4 Edge, identity, integrations — [R070](../../tasks/PENDING.R070.dev_edge_services.md)

| ID | Task | Done | Diagram box |
|----|------|------|-------------|
| D1-14 | Route 53 hosted zone + ACM certificate | [ ] | Add to diagram — [D-3](./CLOUDFORMATION_PLAN.md#7-open-decisions) |
| D1-15 | API Gateway or ALB + CloudFront for SPAs | [ ] | AWS API Gateway |
| D1-16 | Cognito user pool + app clients; replace dev `login.html` | [ ] | AWS Cognito — or interim welcome JWT [D-2](./CLOUDFORMATION_PLAN.md#7-open-decisions) |
| D1-17 | Welcome/login URL → Cognito hosted UI or custom domain | [ ] | Add **Welcome / Login** box |
| D1-18 | SES verified domain + IAM for transactional email | [ ] | AWS SES — may defer |
| D1-19 | Stripe test mode: Checkout + webhooks to customer_api | [ ] | Stripe (Test Mode) — application config |
| D1-20 | CloudWatch logs/metrics; optional Prometheus sidecar | [ ] | Add observability note |

### 1.5 Delivery — [R010](../../tasks/SHIPPED.R010.repo_bootstrap.md) ✓, [R100](../../tasks/PENDING.R100.cicd_ecs_deploy.md), [R080](../../tasks/PENDING.R080.pilot_coordinator.md)

| ID | Task | Done |
|----|------|------|
| D1-21 | IaC repo — [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation); see [CLOUDFORMATION_PLAN.md](./CLOUDFORMATION_PLAN.md) | [x] |
| D1-22 | CD workflow: merge to `main` → build → push image → deploy ECS on MentorHub-Dev | [ ] |
| D1-23 | Environment config via task env / Secrets Manager (not rebuilt images) | [ ] |
| D1-24 | Smoke test: portal login → one journey SPA → one API round-trip | [ ] |

**Exit criteria (Milestone A):** MentorHub-Dev URL reachable; sign-in (Cognito or interim welcome); coordinator journey round-trip; data in DocumentDB.  
**Exit criteria (Milestone B):** All journeys deployed; merge-to-deploy CI/CD; diagrams match deployed architecture. See [LiveDevPlan.md](./LiveDevPlan.md).

---

## Phase 2 — Staging

**CF task:** [R120](../../tasks/PENDING.R120.staging.md) · **Status:** Not started

| ID | Task | Done |
|----|------|------|
| S2-1 | Decide account model (new `MentorHub-Staging` vs shared account) | [ ] |
| S2-2 | Create `ArchitectureDiagram.staging.drawio` + `.svg` | [ ] |
| S2-3 | Copy Phase 1 stack with staging config and test data policy | [ ] |
| S2-4 | CD promotion: promote immutable image from dev → staging | [ ] |
| S2-5 | Automated tests gate before prod promotion | [ ] |

---

## Phase 3 — Production

**CF task:** [R130](../../tasks/PENDING.R130.production.md) · **Status:** Not started

| ID | Task | Done |
|----|------|------|
| S3-1 | Production AWS account + stricter IAM | [ ] |
| S3-2 | Create `ArchitectureDiagram.production.drawio` + `.svg` | [ ] |
| S3-3 | Production IdP (Cognito or commercial IdP per sre_standards) | [ ] |
| S3-4 | DocumentDB backup / restore runbook | [ ] |
| S3-5 | Production checklist in sre_standards (JWT, TLS, budgets, CloudTrail) | [ ] |
| S3-6 | Stripe live mode cutover | [ ] |

---

## Diagram deliverables

| File | Purpose | Status |
|------|---------|--------|
| `ArchitectureDiagram.local.*` | Docker Desktop stack | Done — [mentorhub/Specifications](https://github.com/mentor-forge/mentorhub/tree/main/Specifications) |
| `ArchitectureDiagram.dev.*` | MentorHub-Dev AWS | **WIP** — [dev guide](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.guide.md) |
| `ArchitectureDiagram.staging.*` | Staging | Not started |
| `ArchitectureDiagram.production.*` | Production | Not started |
| `InfrastructureDiagram.svg` | Platform / account view | In this repo — update at [R110](../../tasks/PENDING.R110.documentation_hygiene.md) |
| Optional: `ArchitectureDiagram.platform.*` | Shared-Services, CodeArtifact, CI | Not started |

After each diagram edit: export SVG, commit both `.drawio` and `.svg`, update architecture docs in mentorhub.

---

## CloudFormation task map (Phase 0 + Phase 1)

Quick reference from platform plan items to executable tasks. Full detail in task files.

| Platform phase | CF tasks | Status |
|----------------|----------|--------|
| IaC bootstrap | R010 | ✓ Shipped |
| CodeArtifact import | R020 | Running |
| ECR + GHCR dual-push | R030 | **Now** |
| Shared-Services governance | R031 | Pending |
| Dev network + governance | R040 | Pending |
| Dev DocumentDB + secrets | R050 | Pending |
| Dev ECS platform | R060 | Pending |
| Dev edge (API GW, Cognito, DNS, SES) | R070 | Pending |
| Coordinator pilot | R080 | Pending — **Milestone A** |
| All journeys | R090 | Pending |
| CI/CD to ECS | R100 | Pending |
| Docs hygiene | R110 | Pending |

---

## Cost sketch (for fundraising alignment)

| Account / env | Monthly budget (documented) | Primary spend |
|---------------|----------------------------|---------------|
| Shared-Services | $25 | CodeArtifact, ECR, CloudTrail |
| MentorHub-Dev | $50 | ECS Fargate, DocumentDB, NAT, gateway |
| Staging | TBD | Same classes, smaller sizing |
| Production | TBD | HA DocumentDB, multi-AZ, higher task count |

Campaign 3 in [FundraisingCampaigns.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/FundraisingCampaigns.md) maps to Phase 0 + Phase 1 ops funding. Phase 0 package/registry work is largely complete; remaining spend is Dev runtime (Phase 1).

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-11 | Initial plan; links dev diagram box-by-box guide |
| 2026-06-25 | Refresh: as-built org includes Shared-Services; Phase 0 checkboxes updated; Phase 1 status + CF task links; LiveDevPlan cross-ref |
