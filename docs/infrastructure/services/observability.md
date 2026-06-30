# Observability

**AWS:** CloudWatch Logs, CloudWatch Metrics, CloudTrail, optional alarms → SNS

## Logging

| Source | Destination |
|--------|-------------|
| ECS tasks | CloudWatch Logs (`/mentorhub/<env>/<service>`) |
| API Gateway | Access logs (enable at R070) |
| AWS API calls | CloudTrail per account |

## Metrics and alarms

- ECS CPU/memory utilization
- DocumentDB connections and latency
- API Gateway 4xx/5xx rates
- Budget alarms per account (Shared-Services ~$25, Dev ~$50–100)

## Application observability (future)

Prometheus, Grafana, ELK mentioned in sre_standards — application-level; not blocking first cloud deploy.

## Audit

CloudTrail required on Shared-Services (R031) and all workload accounts.
