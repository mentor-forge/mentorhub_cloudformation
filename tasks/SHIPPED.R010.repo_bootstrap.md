# R010 – Repo and tooling bootstrap

**Status**: Shipped  
**Task Type**: Infrastructure  
**Run Mode**: Sequential

## Goal

Establish the dedicated `mentorhub_cloudformation` repository with layout, deploy scripts, parameters, naming conventions, and CI lint — isolated from mentorhub welcome/login CI.

## Context / Input files

- [mentorhub/Specifications/architecture.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/architecture.yaml)
- [mentorhub/Specifications/aws-platform.yaml](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/aws-platform.yaml)
- [mentorhub/Specifications/CLOUDFORMATION_CHECKLIST.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/CLOUDFORMATION_CHECKLIST.md)
- [mentorhub/Specifications/InfrastructureDiagram.svg](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/InfrastructureDiagram.svg)

## Requirements

- [x] **R010.1** Create GitHub repo `mentor-forge/mentorhub_cloudformation` (not under `mentorhub/infrastructure/`)
- [x] **R010.2** Root `README.md`: stack order, profiles, rollback, links to Specifications
- [x] **R010.3** `parameters/shared-services.json` (values from aws-platform.yaml)
- [ ] **R010.4** `parameters/dev.json` (record MentorHub-Dev account ID when confirmed) — **TBD** until account provisioned
- [x] **R010.5** `scripts/deploy-stack.sh` (`aws cloudformation deploy --profile …`)
- [x] **R010.6** GitHub Action `.github/workflows/cfn-lint.yml` on `templates/**/*.yaml`
- [x] **R010.7** Document naming: `mentorhub-<env>-<component>` stacks; tags `Project=MentorHub`, `Environment`, `ManagedBy=CloudFormation`
- [ ] **R010.8** SRE can `aws sso login --profile mentorhub-shared` and `mentorhub-dev` — **manual verify** per operator workstation
- [x] **R010.9** `tasks/README_SRE.md` and sample task in place

## Validation expectations

- `cfn-lint templates/**/*.yaml` passes (sample template acceptable for bootstrap).
- `chmod +x scripts/deploy-stack.sh`
- GitHub Actions `cfn-lint` workflow green on `main`.
- SSO login succeeds for both profiles.

## Dependencies / Ordering

- First task in the sequence. No dependencies.

## Exit criteria

Empty IaC layout merged; lint passes on a sample template; repo linked from mentorhub checklist.

## Change control checklist

- [x] Reviewed all **Context / Input files**.
- [x] Documented solution approach in this file.
- [x] Implemented repo structure and bootstrap files.
- [x] Ran `cfn-lint`; no unresolved errors (after sample template fix).
- [x] CI workflow passes.
- [ ] SSO profiles verified (operator manual step).
- [x] Created a scoped commit referencing R010.

## Implementation notes

**Summary of changes**
- Created `mentor-forge/mentorhub_cloudformation` on GitHub; pushed bootstrap to `main` via SSH remote.
- Local clone: `/home/lukestill/source/mentor-forge/mentorhub_cloudformation`, tracking `origin/main`.
- Added to `mentorhub.code-workspace` after `mentorhub`.
- Fixed `templates/shared-services/sample.yaml` (WaitConditionHandle placeholder) so `cfn-lint` CI passes.
- Added `.gitignore`.

**Validation results**
- `deploy-stack.sh` executable (`chmod +x`).
- Initial CI failed on W3011 (S3 DeletionPolicy); fixed in follow-up commit.
- SSO: not verified in automation — run `aws sso login --profile mentorhub-shared` and `mentorhub-dev` locally.

**Follow-up tasks**
- R010.4: update `parameters/dev.json` when MentorHub-Dev account ID is confirmed.
- R020: CodeArtifact import.
