# Integrations

## Stripe

| Environment | Mode |
|-------------|------|
| Local | Stripe mock (commented in compose — enable) |
| Dev / Staging | Stripe test mode |
| Production | Stripe live |

**Flows:**
- customer_api → Stripe Checkout (outbound HTTPS via NAT)
- Stripe → API Gateway `/webhooks/stripe` → customer_api (inbound)

## Events collection

`Event` is a logical MongoDB collection written by multiple journey APIs — not a separate AWS service. Used for analytics and aggregation pipelines.

## Runbook automation

`runbook_api` (port 8395) — optional in Dev; may run as ECS task or GitHub workflow for operational jobs.
