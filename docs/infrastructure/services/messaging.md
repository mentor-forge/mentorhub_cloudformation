# Messaging (email)

**AWS:** Amazon SES  
**Local:** MailHog (to be added to compose)

## Mapping

| Environment | SMTP |
|-------------|------|
| Local | MailHog (`1025` SMTP, web UI `8025`) |
| Dev | SES sandbox (verified recipients only) |
| Staging | SES sandbox or verified domain |
| Production | SES production with DKIM/SPF |

## APIs that send mail

| API | Use case |
|-----|----------|
| customer_api | Subscription / billing notices |
| coordinator_api | Invite / match emails |
| mentor_api | Session notifications (future) |

## Compose gap

MailHog is referenced in [ArchitectureDiagram.dev.guide.md](https://github.com/mentor-forge/mentorhub/blob/main/Specifications/ArchitectureDiagram.dev.guide.md) but **not yet in docker-compose.yaml**. Add as a planning follow-up in mentorhub (application repo), not blocking IaC.

## Configuration

- APIs use SMTP env vars (`SMTP_HOST`, `SMTP_PORT`, etc.)
- Cloud: SES SMTP credentials or SES API via IAM role on ECS task
