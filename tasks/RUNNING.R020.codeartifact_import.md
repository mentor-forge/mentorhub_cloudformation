# R020 – Shared-Services: CodeArtifact import

**Status**: Running  
**Task Type**: Import  
**Run Mode**: Sequential

## Goal

Bring existing CodeArtifact domain and repositories under CloudFormation management via resource import — **do not recreate** resources.

## Context / Input files

- [docs/specifications/INFO.md](../docs/specifications/INFO.md) — as-built commands
- [docs/specifications/aws-platform.yaml](../docs/specifications/aws-platform.yaml)
- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)

### Existing resources (import targets)

| Resource | Name |
|----------|------|
| Domain | `mentor-forge` |
| PyPI repo | `mentorhub-pypi` (+ `public:pypi`) |
| npm repo | `mentorhub-npm` (+ `public:npmjs`) |
| Account | `560167829275` |

## Requirements

- [x] **R020.1** Add template `templates/shared-services/codeartifact.yaml` matching INFO.md
- [x] **R020.2** Plan CloudFormation **resource import** for domain + both repositories
- [ ] **R020.3** Run import change set (`--import-existing-resources`)
- [ ] **R020.4** Stack update: ensure external connections `public:pypi` and `public:npmjs` match INFO.md
- [ ] **R020.5** Tag imported resources
- [ ] **R020.6** Validate: `aws codeartifact list-repositories-in-domain --domain mentor-forge --domain-owner 560167829275 --region us-east-1 --profile mentorhub-shared`
- [ ] **R020.7** Validate: local `mh` → `pipenv run install` / `npm ci` in a consumer repo
- [ ] **R020.8** Validate: GitHub tag publish still reaches CodeArtifact

## Validation expectations

- `cfn-lint templates/shared-services/codeartifact.yaml`
- `aws cloudformation validate-template` with `--profile mentorhub-shared`
- Import change set dry-run reviewed before apply.
- Consumer package install and publish unchanged.

## Dependencies / Ordering

- **After:** `SHIPPED.R010.repo_bootstrap.md`

## Exit criteria

CodeArtifact under CloudFormation management with zero consumer breakage.

## Change control checklist

- [x] Reviewed INFO.md and aws-platform.yaml.
- [x] Template matches live resource identifiers.
- [ ] Import change set dry-run reviewed.
- [ ] Post-import CLI and consumer smoke tests passed.
- [ ] Scoped commit referencing R020.

## Implementation notes

**Summary of changes**

- Implemented `templates/shared-services/codeartifact.yaml` with `MentorForgeDomain`, `PypiRepository`, and `NpmRepository` resources matching INFO.md (domain KMS key, descriptions, external connections). `DeletionPolicy: Retain` on all resources.
- Added `import/codeartifact-resources-to-import.json` mapping logical IDs to live resource identifiers.
- Added `scripts/import-codeartifact-stack.sh` with `preflight`, `plan`, `execute`, `validate`, `smoke`, and `apply-tags` subcommands.

**Import procedure (SRE — Shared-Services role `SRE`, not `Developer-Packages`)**

```sh
cd mentorhub_cloudformation
aws sso login --profile mentorhub-shared   # must assume SRE for plan/execute

# 0. Read-only preflight (Developer-Packages OK)
./scripts/import-codeartifact-stack.sh preflight

# 1. Lint + validate + create reviewable IMPORT change set
./scripts/import-codeartifact-stack.sh plan

# 2. Review change set output, then execute import + CLI smoke (R020.6)
./scripts/import-codeartifact-stack.sh execute

# 3. Apply resource tags (R020.5)
./scripts/import-codeartifact-stack.sh apply-tags

# 4. Consumer smoke tests (R020.7, R020.8) — manual
```

**Validation results**

- `cfn-lint templates/shared-services/codeartifact.yaml` — pass (2026-06-24, `.venv`)
- `./scripts/import-codeartifact-stack.sh preflight` — pass (2026-06-24): live domain KMS, repo upstreams, descriptions match template
- R020.7 partial — `mh` + `npm ci` in `mentorhub_customer_spa` OK (Developer-Packages)
- `aws cloudformation validate-template` / `plan` / `execute` — **blocked**: `mentorhub-shared` uses `Developer-Packages` (no CloudFormation). SRE role required on Shared-Services.
- Import execute + smoke — pending SRE run after PR #2 merge

**Follow-up tasks**

- None. R030 follows after R020 ships.
