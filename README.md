# MentorHub CloudFormation

Dedicated infrastructure-as-code repository for MentorHub AWS CloudFormation stacks. **SRE specifications, platform runbooks, and IaC tasks live here** — isolated from the main [mentorhub](https://github.com/mentor-forge/mentorhub) repo (product specs, Developer Edition, journey apps).

## Roadmap — Cloud Dev (Now / Next / Later)

**Goal:** MentorHub deployed and reachable in **AWS MentorHub-Dev** (sign-in + at least one journey end-to-end).

We use a lightweight **Now → Next → Later** rhythm — one feature at a time, promoted when shipped. **Now** is automated via [tasks/](./tasks/) (R010–R130).

| | Feature |
|---|---------|
| **Now** | ECR provisioning + GHCR ↔ ECR dual-push ([R030](./tasks/RUNNING.R030.ecr_ghcr_connection.md)) |
| **Next** | Dev infrastructure (VPC, DocumentDB, ECS, edge) → coordinator pilot → CI/CD → all journeys |
| **Later** | Test envs in Dev account · staging · production |

Full map (current state → live Dev): **[docs/specifications/CloudDevRoadmap.md](./docs/specifications/CloudDevRoadmap.md)**

## Documentation

| Location | Purpose |
|----------|---------|
| [`docs/README.md`](./docs/README.md) | SRE doc index |
| [`docs/specifications/`](./docs/specifications/) | Platform specs: CLOUDFORMATION_*, DEPENDENCY_MOVE, aws-platform.yaml, INFO.md, diagrams |
| [`tasks/README.md`](./tasks/README.md) | SRE task workflow (R010–R130) |

**Product architecture** (journeys, local/dev diagrams, `architecture.yaml`) stays in [mentorhub/Specifications](https://github.com/mentor-forge/mentorhub/tree/main/Specifications).

## Task workflow

Implementation work is tracked as discrete tasks under [`tasks/`](./tasks/). Start with [`tasks/README.md`](./tasks/README.md).

## Repository layout

```text
mentorhub_cloudformation/
├── README.md
├── docs/
│   ├── README.md
│   └── specifications/          # SRE platform specs (moved from mentorhub)
├── parameters/
│   ├── shared-services.json
│   ├── dev.json
│   ├── staging.json
│   └── production.json
├── scripts/
│   ├── deploy-stack.sh
│   └── import-codeartifact-stack.sh   # R020 import workflow
├── import/
│   └── codeartifact-resources-to-import.json
├── templates/
│   ├── shared-services/
│   └── dev/
├── tasks/
│   ├── README.md
│   └── PENDING|RUNNING|SHIPPED.R*.md
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

# R020 — CodeArtifact import (see tasks/RUNNING.R020.codeartifact_import.md)
aws sso login --profile mentorhub-shared   # SRE role required for plan/execute
./scripts/import-codeartifact-stack.sh preflight   # read-only live vs template check
./scripts/import-codeartifact-stack.sh plan      # create import change set for review
./scripts/import-codeartifact-stack.sh execute   # run import + CLI smoke test
./scripts/import-codeartifact-stack.sh apply-tags
```

## Rules

- One stack per PR. Validate before deploy.
- Do **not** delete and recreate CodeArtifact — **import** from [docs/specifications/INFO.md](./docs/specifications/INFO.md).
- Stack naming: `mentorhub-<env>-<component>`.
