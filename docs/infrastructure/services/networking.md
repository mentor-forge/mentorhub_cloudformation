# Networking

**AWS:** VPC, subnets, NAT Gateway, security groups, optional Client VPN  
**Tasks:** R040 · **Feature:** F003

## Layout (MentorHub-Dev)

| Zone | Contents |
|------|----------|
| Public subnets | NAT Gateway, API Gateway VPC Link endpoint, optional bastion |
| Private subnets | ECS Fargate tasks, DocumentDB |

**CIDR:** `10.0.0.0/16` (from `parameters/dev.json`)

## Security groups

```text
Internet → API Gateway (AWS managed)
API Gateway VPC Link → ALB → ECS tasks
ECS tasks → DocumentDB (27017)
ECS tasks → NAT → Stripe, SES, external APIs
```

## Developer access ([D-6](../infrastructure.yaml))

- **Default:** IAM Identity Center only; no VPN required for app deploy
- **Optional:** AWS Client VPN for direct DocumentDB debugging

## Diagram

Rename diagram swimlanes per [ArchitectureDiagram.dev.guide.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.guide.md) Boxes 2–3.
