# GitHub organization CI — `mentor-forge`

Canonical values for org variables live in [config/aws-platform.yaml](../config/aws-platform.yaml). This document describes **what is implemented today** in GitHub Actions across MentorHub repos: workflows, org-level configuration, AWS OIDC roles, and how Docker builds authenticate to CodeArtifact.

**Organization:** [github.com/mentor-forge](https://github.com/mentor-forge)  
**Settings:** [Organization variables and secrets](https://github.com/organizations/mentor-forge/settings/secrets/actions)

---

## Organization variables

Visibility: **All repositories**. Workflows reference these as `vars.<NAME>`. Several journey workflows include inline fallbacks matching Shared-Services defaults so local forks still build if a variable is missing.

| Variable | Value | Used for |
|----------|-------|----------|
| `AWS_REGION` | `us-east-1` | `aws-actions/configure-aws-credentials` region; CodeArtifact API calls |
| `AWS_SHARED_SERVICES_ACCOUNT_ID` | `560167829275` | CodeArtifact domain owner; token and repository endpoint lookups |
| `CODEARTIFACT_DOMAIN` | `mentor-forge` | CodeArtifact domain name |
| `CODEARTIFACT_PYPI_REPO` | `mentorhub-pypi` | Python package index (`api-utils`, API `pip install`) |
| `CODEARTIFACT_NPM_REPO` | `mentorhub-npm` | npm registry (`@mentor-forge/mentorhub_spa_utils`, SPA `npm ci`) |

---

## Organization secrets

Visibility: **All repositories**. These store **IAM role ARNs only** — not long-lived AWS access keys. GitHub Actions assumes each role via OIDC (`id-token: write` permission required).

| Secret | IAM role (Shared-Services) | Used by |
|--------|------------------------------|---------|
| `AWS_ROLE_ARN_READ` | `GitHubActionsCodeArtifactRead` | Journey API/SPA `docker-push.yml` on push to `main` |
| `AWS_ROLE_ARN_PUBLISH` | `GitHubActionsCodeArtifactPublish` | `mentorhub_api_utils` and `mentorhub_spa_utils` `publish-package.yml` on tag `v*` |

**Planned (not yet in org secrets):**

| Secret | IAM role | Task |
|--------|----------|------|
| `AWS_ROLE_ARN_ECR_PUSH` | `GitHubActionsECRPush` | R030 — dual-push GHCR + ECR |
| `AWS_ROLE_ARN_ECS_DEPLOY` | `GitHubActionsECSDeploy` | R100 — ECS rollout workflows |

Role ARNs follow `arn:aws:iam::560167829275:role/<RoleName>`. Record deployed ARNs in `config/aws-platform.yaml` after IaC import (R031).

### Built-in workflow secret

| Secret | Source | Used for |
|--------|--------|----------|
| `GITHUB_TOKEN` | Auto-injected per workflow | `docker/login-action` to `ghcr.io`; package write for container publish |

No org secret is required for GHCR login when `packages: write` is granted to the job.

---

## AWS OIDC (Shared-Services account)

GitHub Actions authenticates to AWS using **web identity federation** — no static access keys in repositories.

| Component | Value |
|-----------|-------|
| OIDC provider | `arn:aws:iam::560167829275:oidc-provider/token.actions.githubusercontent.com` |
| Audience | `sts.amazonaws.com` |
| Account | Shared-Services (`560167829275`) |

### `GitHubActionsCodeArtifactRead`

**Purpose:** Short-lived CodeArtifact read token during Docker image builds.

**Trust (summary):** `repo:mentor-forge/<journey_*_api|*_spa>:ref:refs/heads/main` for each journey repo that runs `docker-push.yml`.

**Permissions:** `codeartifact:GetAuthorizationToken`, `GetRepositoryEndpoint`, `ReadFromRepository` on domain `mentor-forge` and repos `mentorhub-pypi`, `mentorhub-npm`; `sts:GetServiceBearerToken`.

### `GitHubActionsCodeArtifactPublish`

**Purpose:** Publish `api-utils` and `@mentor-forge/mentorhub_spa_utils` on version tags.

**Trust (summary):** `repo:mentor-forge/mentorhub_api_utils:ref:refs/tags/v*` and `repo:mentor-forge/mentorhub_spa_utils:ref:refs/tags/v*`.

**Permissions:** Read + `PublishPackageVersion`, `PutPackageMetadata` on the same CodeArtifact resources.

Step-by-step console setup (historical): [archive/DEPENDENCY_MOVE.md](./archive/DEPENDENCY_MOVE.md) § 0.2–0.3. Codify in CloudFormation: R031.

---

## Workflow patterns

### 1. Journey API — `docker-push.yml`

**Trigger:** `push` to `main`  
**Example repos:** `mentorhub_coordinator_api`, `mentorhub_customer_api`, `mentorhub_mentee_api`, `mentorhub_mentor_api`

```text
checkout → OIDC assume AWS_ROLE_ARN_READ → CodeArtifact pip token
        → docker buildx → GHCR push ghcr.io/mentor-forge/<repo>:latest
```

| Step | Detail |
|------|--------|
| Permissions | `contents: read`, `packages: write`, `id-token: write` |
| Platforms | `linux/amd64`, `linux/arm64` |
| CodeArtifact | Build `PIP_INDEX_URL` with 12-hour token; pass as Docker `build-arg` |
| Registry output | `ghcr.io/mentor-forge/<repo_name>:latest` |

**Dockerfile pattern (API):**

- Multi-stage `python:3.12-slim` build
- `ARG PIP_INDEX_URL` — install locked deps from CodeArtifact during build stage only
- Production stage copies site-packages; **no tokens** in final image
- `gunicorn` serves `src.server:app` on container port (e.g. `8389`)

### 2. Journey SPA — `docker-push.yml`

**Trigger:** `push` to `main`  
**Example repos:** `mentorhub_coordinator_spa`, `mentorhub_customer_spa`, `mentorhub_mentee_spa`, `mentorhub_mentor_spa`

```text
checkout → OIDC assume AWS_ROLE_ARN_READ → CodeArtifact npm token
        → docker buildx (BuildKit secret) → GHCR push
```

| Step | Detail |
|------|--------|
| Permissions | `contents: read`, `packages: write`, `id-token: write`, `actions: write` (GHA cache) |
| CodeArtifact | npm token passed as BuildKit secret `codeartifact_token` |
| Cache | `cache-from` / `cache-to` `type=gha` |
| Registry output | `ghcr.io/mentor-forge/<repo_name>:latest` |

**Dockerfile pattern (SPA):**

- Build stage: `node:24-alpine`; `.npmrc` scoped to `@mentor-forge` CodeArtifact registry
- `RUN --mount=type=secret,id=codeartifact_token` appends auth token for `npm ci` / `npm install`
- `npm run build` produces static assets
- Deploy stage: `nginx:stable-alpine`; `envsubst` on `nginx.conf.template` for `API_HOST` / `API_PORT`
- Proxies `/api/*` to the paired API container at runtime

### 3. Shared libraries — `publish-package.yml`

**Trigger:** `push` tag matching `v*` (tag must match `pyproject.toml` or `package.json` version)

| Repo | Package | Registry |
|------|---------|----------|
| `mentorhub_api_utils` | `api-utils` (import `api_utils`) | CodeArtifact PyPI `mentorhub-pypi` |
| `mentorhub_spa_utils` | `@mentor-forge/mentorhub_spa_utils` | CodeArtifact npm `mentorhub-npm` |

Uses `secrets.AWS_ROLE_ARN_PUBLISH` and org `vars.*` for domain/repo/account.

### 4. Legacy GHCR-only — `docker-push.yml`

**No CodeArtifact OIDC.** Uses `GITHUB_TOKEN` only to push to GHCR.

| Repo | Notes |
|------|-------|
| `mentorhub` (welcome) | `GITHUB_TOKEN` build-arg for git-based deps |
| `mentorhub_mongodb_api` | Same pattern |
| `mentorhub_runbook_api` | Same pattern |

These repos are candidates for migration to the CodeArtifact workflow pattern when their dependencies move off git URLs.

### 5. Infrastructure — `cfn-lint.yml`

**Repo:** `mentorhub_cloudformation` only  
**Trigger:** `push` and `pull_request` to `main`  
**No AWS secrets** — installs `cfn-lint` and lints `templates/**/*.yaml`.

---

## Repository inventory (CI as of review)

| Repository | Workflow | CodeArtifact OIDC | GHCR on `main` | Tag publish |
|------------|----------|---------------------|----------------|-------------|
| `mentorhub_coordinator_api` | `docker-push.yml` | Yes (PyPI) | Yes | — |
| `mentorhub_customer_api` | `docker-push.yml` | Yes | Yes | — |
| `mentorhub_mentee_api` | `docker-push.yml` | Yes | Yes | — |
| `mentorhub_mentor_api` | `docker-push.yml` | Yes | Yes | — |
| `mentorhub_coordinator_spa` | `docker-push.yml` | Yes (npm) | Yes | — |
| `mentorhub_customer_spa` | `docker-push.yml` | Yes | Yes | — |
| `mentorhub_mentee_spa` | `docker-push.yml` | Yes | Yes | — |
| `mentorhub_mentor_spa` | `docker-push.yml` | Yes | Yes | — |
| `mentorhub_api_utils` | `publish-package.yml` | Yes (publish) | — | `v*` → PyPI |
| `mentorhub_spa_utils` | `publish-package.yml` | Yes (publish) | — | `v*` → npm |
| `mentorhub` | `docker-push.yml` | No | Yes | — |
| `mentorhub_mongodb_api` | `docker-push.yml` | No | Yes | — |
| `mentorhub_runbook_api` | `docker-push.yml` | No | Yes | — |
| `mentorhub_cloudformation` | `cfn-lint.yml` | No | No | — |

Canonical workflow templates for new journey repos: [mentorhub DeveloperEdition standards — docker-push-codeartifact.yml](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/examples/docker-push-codeartifact.yml).

---

## End-to-end CI flow (journey services)

```text
Library release (manual tag vX.Y.Z)
  mentorhub_api_utils / mentorhub_spa_utils
       → publish-package.yml → CodeArtifact

Application merge to main
  mentorhub_*_api / mentorhub_*_spa
       → docker-push.yml
            → assume GitHubActionsCodeArtifactRead (OIDC)
            → fetch CodeArtifact token
            → docker build (pip or npm from CodeArtifact)
            → push ghcr.io/mentor-forge/<repo>:latest

Target (R030 / R100 — not yet wired)
       → also push ECR (same digest)
       → promote / deploy workflows → ECS
```

---

## Adding a new journey repo

1. Copy `docker-push.yml` from an existing API or SPA repo (or the standards example).
2. Set image tag to `ghcr.io/mentor-forge/<new_repo>:latest`.
3. Ensure the repo is listed in the **`GitHubActionsCodeArtifactRead`** OIDC trust policy (`refs/heads/main`).
4. Confirm org variables and `AWS_ROLE_ARN_READ` are visible to the repo (org-wide defaults).
5. API Dockerfile: accept `PIP_INDEX_URL` build-arg. SPA Dockerfile: use BuildKit secret `codeartifact_token` and scoped `.npmrc`.
6. When ECR is live (R030), extend workflow for dual-push and add repo to `GitHubActionsECRPush` trust.

---

## Related documents

| Document | Purpose |
|----------|---------|
| [config/aws-platform.yaml](../config/aws-platform.yaml) | Canonical variable values, CodeArtifact ARNs, planned secrets |
| [README.md](../README.md) | Platform CI/CD summary (promote/deploy model) |
| [ARCHITECTURE.md](../ARCHITECTURE.md) | Why OIDC, GHCR+ECR, immutable images |
| [tasks/RUNNING.R030.ecr_ghcr_connection.md](../tasks/RUNNING.R030.ecr_ghcr_connection.md) | ECR + dual-push |
| [tasks/PENDING.R100.cicd_ecs_deploy.md](../tasks/PENDING.R100.cicd_ecs_deploy.md) | ECS deploy workflows |
