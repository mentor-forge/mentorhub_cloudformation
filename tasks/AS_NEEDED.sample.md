# R900 – Example: Import an existing S3 bucket into CloudFormation

**Status**: Planned  
**Task Type**: Import  
**Run Mode**: Run as needed  <!-- options: Sequential | Run as needed -->

## Goal

Import an existing MentorHub S3 bucket into a CloudFormation stack so it is managed by IaC without recreating the bucket or disrupting consumers.

## Context / Input files

These files must be treated as **inputs** and read before implementation:

- `mentorhub/Specifications/architecture.yaml`
- `config/aws-platform.yaml`
- [InfrastructureDiagram.svg](../docs/InfrastructureDiagram.svg)

The agent may also consult:

- AWS docs: [Importing existing resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html)
- Existing templates under `templates/` in this repo

## Requirements

- Add or extend a template (e.g., `templates/dev/s3.yaml`) that describes the bucket's **current** configuration.
- Create a resource import change set with `--import-existing-resources`.
- Apply the import without replacing the bucket.
- Tag imported resources per repo standards (`Project=MentorHub`, `Environment`, `ManagedBy=CloudFormation`).
- Document the import commands in the task implementation notes.

## Validation expectations

- **Lint**
  - `cfn-lint templates/dev/s3.yaml` passes without errors.

- **Validate template**
  - `aws cloudformation validate-template --template-body file://templates/dev/s3.yaml --region us-east-1 --profile mentorhub-dev`

- **Import dry-run**
  - Create change set with `--change-set-type IMPORT` and review resources to import.

- **Post-import smoke**
  - Bucket still accessible; no drift on critical properties (name, encryption, public access block).

## Dependencies / Ordering

- Should run **after**:
  - `PENDING.R040.dev_governance_network.md` (if bucket is VPC-scoped or policy references network).
- Should run **before**:
  - Any task that attaches bucket policies from other stacks.

## Change control checklist

- [ ] Reviewed all **Context / Input files**.
- [ ] Documented solution approach in this file.
- [ ] Implemented template and parameter changes.
- [ ] Ran `cfn-lint`; no unresolved errors.
- [ ] Ran `aws cloudformation validate-template`; successful.
- [ ] Ran import change set (dry-run reviewed before apply).
- [ ] Post-import smoke checks passed.
- [ ] Created a scoped commit referencing this task ID.

## Implementation notes (to be updated by the agent)

**Summary of changes**
- _e.g., "Added `templates/dev/s3.yaml`, imported bucket `mentorhub-dev-app-data` into stack `mentorhub-dev-s3`."_

**Validation results**
- cfn-lint: _command and outcome_
- validate-template: _command and outcome_
- Import: _change set ID, stack name, outcome_
- Smoke: _checks performed_

**Follow-up tasks**
- _e.g., "Add lifecycle rules in a separate stack update once retention policy is agreed."_
