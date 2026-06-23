# R020 – Shared-Services: CodeArtifact import

**Status**: Pending  
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

- [ ] **R020.1** Add template `templates/shared-services/codeartifact.yaml` matching INFO.md
- [ ] **R020.2** Plan CloudFormation **resource import** for domain + both repositories
- [ ] **R020.3** Run import change set (`--import-existing-resources`)
- [ ] **R020.4** Stack update: ensure external connections `public:pypi` and `public:npmjs` match INFO.md
- [ ] **R020.5** Tag imported resources
- [ ] **R020.6** Validate: `aws codeartifact list-repositories --domain mentor-forge --domain-owner 560167829275 --region us-east-1 --profile mentorhub-shared`
- [ ] **R020.7** Validate: local `mh` → `pipenv run install` / `npm ci` in a consumer repo
- [ ] **R020.8** Validate: GitHub tag publish still reaches CodeArtifact

## Validation expectations

- `cfn-lint templates/shared-services/codeartifact.yaml`
- `aws cloudformation validate-template` with `--profile mentorhub-shared`
- Import change set reviewed before apply.
- Consumer package install and publish unchanged.

## Dependencies / Ordering

- **After:** `PENDING.R010.repo_bootstrap.md`

## Exit criteria

CodeArtifact under CloudFormation management with zero consumer breakage.

## Change control checklist

- [ ] Reviewed INFO.md and aws-platform.yaml.
- [ ] Template matches live resource identifiers.
- [ ] Import change set dry-run reviewed.
- [ ] Post-import CLI and consumer smoke tests passed.
- [ ] Scoped commit referencing R020.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
