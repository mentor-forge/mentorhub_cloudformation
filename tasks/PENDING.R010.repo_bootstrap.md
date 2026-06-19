# R010 – Repo and tooling bootstrap

**Status**: Pending  
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

- [ ] **R010.1** Create GitHub repo `mentor-forge/mentorhub_cloudformation` (not under `mentorhub/infrastructure/`)
- [ ] **R010.2** Root `README.md`: stack order, profiles, rollback, links to Specifications
- [ ] **R010.3** `parameters/shared-services.json` (values from aws-platform.yaml)
- [ ] **R010.4** `parameters/dev.json` (record MentorHub-Dev account ID when confirmed)
- [ ] **R010.5** `scripts/deploy-stack.sh` (`aws cloudformation deploy --profile …`)
- [ ] **R010.6** GitHub Action `.github/workflows/cfn-lint.yml` on `templates/**/*.yaml`
- [ ] **R010.7** Document naming: `mentorhub-<env>-<component>` stacks; tags `Project=MentorHub`, `Environment`, `ManagedBy=CloudFormation`
- [ ] **R010.8** SRE can `aws sso login --profile mentorhub-shared` and `mentorhub-dev`
- [ ] **R010.9** `tasks/README_SRE.md` and sample task in place

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

- [ ] Reviewed all **Context / Input files**.
- [ ] Documented solution approach in this file.
- [ ] Implemented repo structure and bootstrap files.
- [ ] Ran `cfn-lint`; no unresolved errors.
- [ ] CI workflow passes.
- [ ] SSO profiles verified.
- [ ] Created a scoped commit referencing R010.

## Implementation notes

**Summary of changes**

**Validation results**

**Follow-up tasks**
