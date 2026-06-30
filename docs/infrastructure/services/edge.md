# Edge (API Gateway, DNS, TLS)

**AWS:** API Gateway HTTP API, Route 53, ACM, optional CloudFront  
**Tasks:** R070 · **Feature:** F004  
**Decisions:** D-3 (domain/TLS), D-7 (SPA delivery), D-8 (routing)

## API Gateway

Single public HTTPS entry for all journey SPAs and webhook paths.

| Route | Target |
|-------|--------|
| `/coordinator/*` | coordinator SPA + API (via VPC Link → ALB → ECS) |
| `/mentor/*` | mentor SPA + API |
| `/mentee/*` | mentee SPA + API |
| `/customer/*` | customer SPA + API |
| `/webhooks/stripe` | customer_api |
| `/oauth/*` or redirects | Cognito |

Browser never connects directly to ECS task IPs.

## TLS and DNS

- **Route 53** hosted zone for owned domain ([D-3](../infrastructure.yaml))
- **ACM** certificates for gateway (and CloudFront if used)
- Interim option: HTTP-only internal URL for first pilot — document rationale if chosen

## SPA delivery ([D-7](../infrastructure.yaml))

| Option | Pros | Cons |
|--------|------|------|
| ECS nginx containers | Matches compose today | Higher task count |
| S3 + CloudFront | Cheaper static hosting | Extra pipeline for SPA assets |

Default for pilot: **ECS containers** (parity with compose). Revisit at R090.

## Local parity

Optional traefik/nginx in compose to practice path routing. Not required for daily dev.
