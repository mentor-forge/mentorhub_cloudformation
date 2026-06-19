This folder contains SRE / infrastructure tasks that a long-running agent session can execute one at a time, based on the context and instructions in each task file.

Adapted from the `tasks/README.md` pattern in MentorHub API repos (`mentorhub_coordinator_api`, etc.), with change control tailored to CloudFormation work instead of Pipenv unit/e2e tests.

**Checklist index:** [CLOUDFORMATION_CHECKLIST.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/CLOUDFORMATION_CHECKLIST.md)

### Task index

| Task | Phase | Status | File |
|------|-------|--------|------|
| R010 | 0 | Shipped | [SHIPPED.R010.repo_bootstrap.md](./SHIPPED.R010.repo_bootstrap.md) |
| R020 | 1 | Pending | [PENDING.R020.codeartifact_import.md](./PENDING.R020.codeartifact_import.md) |
| R030 | 2 | Pending | [PENDING.R030.shared_services_oidc_ecr.md](./PENDING.R030.shared_services_oidc_ecr.md) |
| R040 | 3A | Pending | [PENDING.R040.dev_governance_network.md](./PENDING.R040.dev_governance_network.md) |
| R050 | 3B | Pending | [PENDING.R050.dev_data_secrets.md](./PENDING.R050.dev_data_secrets.md) |
| R060 | 3C | Pending | [PENDING.R060.dev_compute_platform.md](./PENDING.R060.dev_compute_platform.md) |
| R070 | 3D | Pending | [PENDING.R070.dev_edge_services.md](./PENDING.R070.dev_edge_services.md) |
| R080 | 4 | Pending | [PENDING.R080.pilot_coordinator.md](./PENDING.R080.pilot_coordinator.md) |
| R090 | 5 | Pending | [PENDING.R090.remaining_dev_services.md](./PENDING.R090.remaining_dev_services.md) |
| R100 | 6 | Pending | [PENDING.R100.cicd_ecs_deploy.md](./PENDING.R100.cicd_ecs_deploy.md) |
| R110 | 7 | Pending | [PENDING.R110.documentation_hygiene.md](./PENDING.R110.documentation_hygiene.md) |
| R120 | 8 | Pending | [PENDING.R120.staging.md](./PENDING.R120.staging.md) |
| R130 | 9 | Pending | [PENDING.R130.production.md](./PENDING.R130.production.md) |

Ad-hoc tasks: [AS_NEEDED.sample.md](./AS_NEEDED.sample.md)

### Task execution workflow

1. **Review all tasks**
   - Each task is a markdown file in this folder (e.g., `PENDING.R020.codeartifact_import.md`).
   - The agent should first **list all tasks**, then determine the **execution order** (see **Task ordering** below).
   - For each task, read the entire file before starting work.

2. **Execute one task at a time**
   - Pick the **next eligible task** (not shipped, not "Run as needed", and in order).
   - Follow the **Task lifecycle** (analysis → implementation → validation → completion notes → change control).
   - Do not start another task until the current one is finished or explicitly deferred.

3. **Change control for each task**
   For every task, the agent should:
   - **Review context**: Read all referenced specification files in [mentorhub/Specifications](https://github.com/mentor-forge/mentorhub/tree/main/Specifications).
   - **Plan changes**: Summarize the planned approach in the notes section of the task file.
   - **Implement changes**: Add or update templates under `templates/`, parameters, scripts, workflows, and docs as required.
   - **Template lint (`cfn-lint`)**:
     - Run `cfn-lint templates/**/*.yaml` (or task-specific paths).
     - Fix all errors; document intentional warnings in the task file.
   - **Template validation (AWS CLI)**:
     - Run `aws cloudformation validate-template` for each new or changed template.
     - Use the correct `--profile` and `--region us-east-1` per stack.
   - **Deploy validation** (when templates are deploy-ready):
     - Use `scripts/deploy-stack.sh` or documented `aws cloudformation deploy` / import commands.
     - For import tasks, run a change set dry-run before applying.
     - Run task-specific smoke checks (CLI, console, or application) listed in the task file.
   - **Commit gating**:
     - Only create a commit once lint, validate-template, and any deploy/smoke checks for the task are in a healthy state.
     - Keep commits scoped to the current task (one stack or logical unit per PR when possible).

4. **Completion and documentation**
   - Update the task file's **status** and **implementation notes**.
   - Rename the file prefix from `PENDING.` to `SHIPPED.` when done.
   - If follow-ups are discovered, add them as new tasks instead of over-expanding the current one.
   - Update [CLOUDFORMATION_CHECKLIST.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/CLOUDFORMATION_CHECKLIST.md) if ordering or scope changes.

### Task ordering

- **Primary mechanism**: A task's filename starts with a sortable prefix: `PENDING.R020_`, `PENDING.R030_`, etc.
- **Execution order**:
  - Sort all task files by filename.
  - Skip tasks explicitly marked as **Run as needed**.
  - Skip tasks with status **Shipped** (or `SHIPPED.` filename prefix).
  - Process remaining tasks in sorted order.
- **Manual overrides**:
  - If a task must run earlier/later, note this in the task's **Dependencies / Ordering** section.

### Task status, categories, and filenames

Each task file should declare status and type **inside the file**, and encode status in the **filename prefix** for IDE grouping.

- **Lifecycle statuses (in-file)**:
  - `Pending`: Not yet started.
  - `Running`: Work is currently being done in the active session.
  - `Blocked`: Waiting on an external dependency or decision.
  - `Shipped`: Implemented, validated, and merged/committed per change control.
  - `Run as needed`: Not part of the main sequence; run manually or opportunistically.

- **Filename status prefixes**:
  - `AS_NEEDED.` — Not part of the main long-running sequence.
  - `BLOCKED.` — Currently blocked.
  - `PENDING.` — Ready when their turn comes.
  - `RUNNING.` — (Optional) Currently being executed.
  - `SHIPPED.` — Fully completed.

- **Recommended filename pattern**:
  - `STATUS.RNNN.short_task_name.md`
  - Examples:
    - `AS_NEEDED.R900.example_import_stack.md`
    - `PENDING.R020.codeartifact_import.md`
    - `SHIPPED.R010.repo_bootstrap.md`

- **Task type** (in-file, optional):
  - `Infrastructure`, `Import`, `CI`, `Docs`, `Chore`, etc.

### Sample task file

See [`AS_NEEDED.sample.md`](./AS_NEEDED.sample.md) for a complete example.

### Marking a task as shipped or "Run as needed"

- **Shipped task**:
  - Update `Status` to `Shipped`.
  - Fill in **Implementation notes** and **Validation results** while commands and outcomes are fresh.
  - Ensure all items in the **Change control checklist** are checked or explicitly skipped with rationale.
  - Rename file prefix from `PENDING.` to `SHIPPED.` after commit.
  - Create a scoped commit referencing the task ID.

- **Run as needed task**:
  - The long-running agent should **not** include these in its default sequential run.

With this structure, a long-running agent can discover tasks, determine order and eligibility, and apply consistent SRE change control (lint → validate → deploy → smoke test → commit) for each task.
