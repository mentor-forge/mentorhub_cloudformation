# Cross-account ECR — authoritative registry and workload pulls

Mentor Forge stores **one authoritative copy** of each journey image in **Shared-Services** ECR. Workload accounts (`mentorhub-dev`, future staging/production) run **ECS Fargate** tasks that **pull** those images — they do not maintain separate build pipelines or duplicate tags.

This is the standard multi-account pattern: platform account owns the registry; application accounts own runtime.

---

## Architecture

```text
GitHub Actions (CI)                    Shared-Services (560167829275)
        │                                        │
        │  OIDC push                             │  ECR repositories
        └──────────────────────────────────────► │  mentorhub-coordinator-api
                                                 │  mentorhub-coordinator-spa
                                                 │  …
                                                 │
Promote (runbook / script)                       │  retag :latest → :test (same digest)
        └──────────────────────────────────────► │
                                                 │
Workload account (e.g. mentorhub-dev 083141433373)
        │
        ├──► (A) Pull-through cache rule ──► local ECR namespace (lazy sync from upstream)
        │         │
        │         └──► ECS task execution role pulls local URI
        │
        └──► (B) Direct cross-account pull ──► Shared-Services URI in task definition
                  (repository policy + execution role)
```

**Write path (only Shared-Services):** merge to `main` → build → push to `560167829275.dkr.ecr.us-east-1.amazonaws.com/<repo>:<tag>`. Promote retags in the **same** registry.

**Read path (workload accounts):** ECS **task execution role** pulls at task start. Two supported consumption models (below); **pull-through cache is the target** for deployed environments; direct pull remains valid for early pilot and tooling.

---

## Why this is not the wrong ECS shape

| Pattern | MentorHub choice | Verdict |
|---------|------------------|---------|
| ECR in every account, copy images on promote | Duplicate storage and drift risk | Avoid |
| ECS in Shared-Services | Violates “no app workloads in platform account” | Avoid |
| **ECR in Shared-Services, ECS in workload accounts** | Matches CodeArtifact split; one promote surface | **Correct** |
| Public GHCR for runtime | Closed by OSS boundary; ECR-only target (R100) | Interim GHCR for local dev only |

Task definitions reference **image digests at deploy time** (resolved from promotion tags). The execution role only needs **pull** — not push — in workload accounts.

---

## Account and URI reference

| Role | Account ID | Registry host |
|------|------------|---------------|
| Authoritative ECR (push + promote) | `560167829275` | `560167829275.dkr.ecr.us-east-1.amazonaws.com` |
| mentorhub-dev (pull) | `083141433373` | `083141433373.dkr.ecr.us-east-1.amazonaws.com` (pull-through target namespace) |

Region: **`us-east-1`** for all ECR and ECS APIs.

Canonical repo list and naming: [`config/aws-platform.yaml`](../config/aws-platform.yaml) → `container_registry.ecr.repositories`.

---

## Layer 1 — Repository policies (Shared-Services)

Each journey repository (or a registry-level policy) in Shared-Services must **trust workload principals** to pull.

**Grant on upstream repositories** (`560167829275`):

| Action | Purpose |
|--------|---------|
| `ecr:BatchCheckLayerAvailability` | Layer existence check before pull |
| `ecr:GetDownloadUrlForLayer` | Download layers |
| `ecr:BatchGetImage` | Pull manifest |
| `ecr:DescribeImages` | Deploy scripts resolve tag → digest |

**Principal (per workload account):** ECS task execution role, e.g.

```text
arn:aws:iam::083141433373:role/mentorhub-dev-ecs-task-execution
```

When staging/production accounts exist, add their execution role ARNs to the same repository policy (or use `ArnLike` on `arn:aws:iam::<workload-account-id>:role/mentorhub-*-ecs-task-execution`).

**Pull-through:** Upstream repositories must also allow the **pull-through cache service** in the consuming account to read manifests. AWS documents this as part of the pull-through rule setup; the Shared-Services repository policy includes the workload account root or the pull-through-linked principal AWS assigns for your rule.

**Implementation:** `templates/shared-services/ecr.yaml` (R030) — `AWS::ECR::Repository` + `AWS::ECR::RepositoryPolicy` parameterized with workload account IDs from `config/aws-platform.yaml`.

Example policy fragment (illustrative — tune in CloudFormation):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowWorkloadAccountPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::083141433373:role/mentorhub-dev-ecs-task-execution"
        ]
      },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability",
        "ecr:DescribeImages"
      ]
    }
  ]
}
```

---

## Layer 2 — ECS task execution role (workload account)

Created in **`templates/dev/ecs-cluster.yaml`** (R060). Attach:

1. **`ecr:GetAuthorizationToken`** on `*` (required; must include `us-east-1` — no account restriction on this action).

2. **Pull permissions** on images the task will use:

   **If using pull-through (target):** repositories in **local** account under the cache prefix, e.g.

   ```text
   arn:aws:ecr:us-east-1:083141433373:repository/mentorhub/*
   ```

   **If using direct cross-account pull (pilot):** upstream repositories in Shared-Services, e.g.

   ```text
   arn:aws:ecr:us-east-1:560167829275:repository/mentorhub-coordinator-api
   ```

The managed policy `AmazonECSTaskExecutionRolePolicy` covers CloudWatch Logs and default ECR **same-account** pull only — extend with an inline policy for cross-account or pull-through repos.

---

## Layer 3 — Pull-through cache (workload account, target)

**Decision:** Deploy an **ECR pull-through cache rule** in each workload account that treats Shared-Services as upstream. First pull of a tag **creates** a cached repository in the workload account and copies layers from upstream; subsequent pulls hit the local copy.

**Why bother if we already have cross-account policies?**

- Keeps bulk layer traffic **inside the workload account** (pairs with **VPC interface endpoints** for ECR — F10).
- Task definitions use **local** registry URIs — simpler IAM and debugging per account.
- Staging/production accounts repeat the same pattern without rewriting task URIs when the upstream account is always Shared-Services.

**Rule shape (conceptual):**

| Field | Value |
|-------|--------|
| Upstream registry | `560167829275.dkr.ecr.us-east-1.amazonaws.com` |
| Repository prefix in workload account | `mentorhub` (matches journey repo naming) |
| Upstream repository mapping | e.g. cached repo `mentorhub/mentorhub-coordinator-api` ← upstream `mentorhub-coordinator-api` |

Exact CloudFormation resource: `AWS::ECR::PullThroughCacheRule` (and repository creation template if used). Implement in **`templates/dev/ecr-pull-through.yaml`** or a subsection of R060/R030 follow-up — **after** upstream repos and repository policies exist.

**Task definition image URI (pull-through):**

```text
083141433373.dkr.ecr.us-east-1.amazonaws.com/mentorhub/mentorhub-coordinator-api:production
```

**Promote still happens only in Shared-Services.** Deploy resolves the tag to a digest from upstream (or from the cached copy’s manifest, which must match upstream after sync).

---

## Layer 4 — Direct cross-account pull (pilot / fallback)

For the first coordinator pilot (R080), it is acceptable to point task definitions **directly** at Shared-Services:

```text
560167829275.dkr.ecr.us-east-1.amazonaws.com/mentorhub-coordinator-api:latest
```

Requires Layer 1 + Layer 2 (upstream ARNs on execution role). Skip Layer 3 until the pull-through stack is deployed.

---

## Developer Edition (local Compose)

Invited contributors pull journey images for `mh pull` / `mh up`:

- **Target (R100.7):** SSO login to Shared-Services (`mentorhub-shared`) + `aws ecr get-login-password` → pull from `560167829275.dkr.ecr.us-east-1.amazonaws.com/...`.
- **Interim:** GHCR (`ghcr.io/mentor-forge/...`) until CI is ECR-only.

Local dev does **not** use pull-through cache — developers and CI authenticate to the authoritative registry.

---

## Implementation checklist

| Task | Deliverable |
|------|-------------|
| R030 | ECR repos + **repository policies** in Shared-Services |
| R060 | ECS task **execution role** with pull IAM |
| R060+ / R070 | **Pull-through cache rule** in mentorhub-dev (optional for pilot; target before full journey rollout) |
| R100 | ECR-only CI; deploy resolves digest from Shared-Services |
| R040 | `com.amazonaws.us-east-1.ecr.api`, `ecr.dkr`, `s3`, `secretsmanager` **interface/gateway endpoints** in workload VPC |

---

## Related documents

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](../ARCHITECTURE.md) | Platform rationale |
| [config/aws-platform.yaml](../config/aws-platform.yaml) | Account IDs, repo names |
| [docs/github-ci.md](./github-ci.md) | CI push (OIDC) to ECR |
| [tasks/RUNNING.R030.ecr_ghcr_connection.md](../tasks/RUNNING.R030.ecr_ghcr_connection.md) | ECR provisioning |
| [tasks/PENDING.R060.dev_compute_platform.md](../tasks/PENDING.R060.dev_compute_platform.md) | Execution role |
