# Identity

**AWS:** Amazon Cognito  
**Tasks:** R070, R080 · **Feature:** F004  
**Decision:** D-2 (interim auth)

## Production target

- **Cognito User Pool** (or external commercial IdP via OIDC)
- SPAs redirect to IdP login; APIs validate JWT via JWKS
- No client-side JWT minting in cloud

## Local today

- `welcome` service (`login.html`) mints persona JWTs with shared `JWT_SECRET`
- `IDP_LOGIN_URI` points SPAs to welcome page

## Interim for first cloud pilot ([D-2](../infrastructure.yaml))

| Option | Use when |
|--------|----------|
| Welcome JWT (secrets in Secrets Manager) | Fastest path to R080 coordinator pilot |
| Cognito-first | Ready for multi-user Dev tenants |

Document chosen path in R070 task before R080 deploy.

## API validation

All journey APIs use `api_utils` JWT validation — same claim expectations as local (`iss`, `aud`, roles). See [api_standards.md](https://github.com/mentor-forge/mentorhub/blob/main/DeveloperEdition/standards/api_standards.md).
