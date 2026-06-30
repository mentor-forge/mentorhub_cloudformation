# AWS accounts

**Status:** Planning roadmap draft

## Organization layout

```text
AWS Organization
└── Root
    ├── Management        — org, Identity Center, billing
    ├── Shared-Services   — CodeArtifact, ECR, GitHub OIDC
    ├── MentorHub-Dev     — multi-tenant dev runtime
    ├── MentorHub-Staging — prod mirror (TBD account model)
    └── MentorHub-Production — live single tenant
```

## Management

- AWS Organizations administration
- IAM Identity Center (SSO region: `us-east-2`)
- Account creation and governance
- No application workloads

## Shared-Services

| Field | Value |
|-------|-------|
| Account ID | `560167829275` |
| CLI profile | `mentorhub-shared` |
| Region | `us-east-1` |
| Budget | ~$100/month (target) |

**Hosts:** CodeArtifact, ECR (planned), GitHub OIDC roles, shared CloudTrail (pending R031).

**Does not host:** application containers, DocumentDB, or journey APIs.

See [services/registry.md](./services/registry.md) and [features/F002-codeartifact-iac.md](./features/F002-codeartifact-iac.md).

## MentorHub-Dev

| Field | Value |
|-------|-------|
| Account ID | TBD ([D-1](../infrastructure.yaml)) |
| CLI profile | `mentorhub-dev` |
| Region | `us-east-1` |
| Budget | ~$100/month |

**Hosts:** VPC, DocumentDB, ECS, API Gateway, Cognito (or interim auth), SES sandbox, S3.

**Tenants:** `dev`, `test`, `training` — see [environments/dev-multi-tenant.md](./environments/dev-multi-tenant.md).

## MentorHub-Staging

| Field | Value |
|-------|-------|
| Account ID | TBD ([D-4](../infrastructure.yaml)) |
| Purpose | Prod mirror; spin down between releases |

See [environments/staging.md](./environments/staging.md).

## MentorHub-Production

| Field | Value |
|-------|-------|
| Account ID | TBD |
| Purpose | Live single-tenant production |

See [environments/production.md](./environments/production.md).

## Human access

All human access via IAM Identity Center. Automation uses OIDC roles — no long-lived access keys in GitHub.

| Account | Developer | SRE |
|---------|-----------|-----|
| Shared-Services | Developer-Packages (CodeArtifact read) | SRE (admin) |
| MentorHub-Dev | Developer | SRE |

Details: [sre_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/sre_standards.md).
