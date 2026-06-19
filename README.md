# MentorHub CloudFormation

Dedicated infrastructure-as-code repository for MentorHub AWS CloudFormation stacks. Keeps SRE deploy workflows and GitHub Actions isolated from the main [mentorhub](https://github.com/mentor-forge/mentorhub) repo (welcome/login pages and developer-edition CI).

## Specifications (inputs)

Authoritative intent lives in the [mentorhub Specifications](https://github.com/mentor-forge/mentorhub/tree/main/Specifications) folder:

| Document | Purpose |
|----------|---------|
| [architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml) | Architecture and infrastructure intent (WIP) |
| [InfrastructureDiagram.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/InfrastructureDiagram.svg) | Platform / account view |
| [ArchitectureDiagram.dev.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.svg) | Application services inside Dev |
| [INFO.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/INFO.md) | As-built CodeArtifact commands |
| [aws-platform.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/aws-platform.yaml) | Region, account IDs, org variables |
| [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/DEPENDENCY_MOVE.md) | OIDC roles, CodeArtifact URLs, CI patterns |
| [CloudEnvironmentPlan.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/CloudEnvironmentPlan.md) | Dev runtime tasks |
| [CLOUDFORMATION_CHECKLIST.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/CLOUDFORMATION_CHECKLIST.md) | Index, timeline, and task ordering |

## Task workflow

Implementation work is tracked as discrete tasks under [`tasks/`](./tasks/). Start with [`tasks/README.md`](./tasks/README.md).

## Repository layout

```text
mentorhub_cloudformation/
├── README.md
├── parameters/
│   ├── shared-services.json
│   ├── dev.json
│   ├── staging.json          # Phase 8
│   └── production.json       # Phase 9
├── scripts/
│   └── deploy-stack.sh
├── templates/
│   ├── shared-services/
│   │   ├── codeartifact.yaml
│   │   ├── github-oidc.yaml
│   │   ├── ecr.yaml
│   │   └── cloudtrail.yaml
│   └── dev/
│       ├── cloudtrail.yaml
│       ├── network.yaml
│       ├── documentdb.yaml
│       ├── secrets.yaml
│       ├── ecs-cluster.yaml
│       ├── api-gateway.yaml
│       ├── cognito.yaml
│       ├── s3.yaml
│       ├── route53-acm.yaml
│       ├── ses.yaml
│       └── ecs-services-*.yaml
├── tasks/
│   ├── README.md
│   └── PENDING.R*.md
└── .github/workflows/
    └── cfn-lint.yml
```

## Prerequisites

- AWS CLI v2 with SSO configured (`mentorhub-shared`, `mentorhub-dev`)
- [`cfn-lint`](https://github.com/aws-cloudformation/cfn-lint)
- Region: `us-east-1` (workloads). SSO Identity Center: `us-east-2`.

## Quick commands

```sh
# Lint all templates
cfn-lint templates/**/*.yaml

# Validate a template (no deploy)
aws cloudformation validate-template \
  --template-body file://templates/shared-services/ecr.yaml \
  --region us-east-1 --profile mentorhub-shared

# Deploy a stack (see scripts/deploy-stack.sh)
./scripts/deploy-stack.sh shared-services ecr mentorhub-shared
```

## Rules

- **One stack per PR** — validate each section before starting the next.
- **Do not recreate CodeArtifact** — import existing resources per [INFO.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/INFO.md).
- Stack naming: `mentorhub-<env>-<component>`
- Tags: `Project=MentorHub`, `Environment`, `ManagedBy=CloudFormation`
