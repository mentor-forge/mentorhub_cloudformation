# F003 — Dev platform (network, data, compute)

**Status:** Planned  
**Tasks:** R040, R050, R060

## Goal

MentorHub-Dev account has VPC, DocumentDB, and ECS cluster ready for application deploy.

## Deliverables

| Task | Stack |
|------|-------|
| R040 | VPC, subnets, NAT, security groups |
| R050 | DocumentDB, Secrets Manager |
| R060 | ECS cluster, execution role, CloudWatch logs |

## Done when

- Private egress from ECS tasks verified
- DocumentDB connectivity smoke test passes
- ECS cluster accepts task runs

## Depends on

- D-1 (Dev account ID)
- D-6 (VPN decision for R040)
- F001 (images in ECR before app deploy)

## Unblocks

F004 (edge), F005 (coordinator pilot)
