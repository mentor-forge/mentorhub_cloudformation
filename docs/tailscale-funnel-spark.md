# Tailscale Funnel & Remote Access (Spark Developer Host)

This guide documents the architecture and deployment procedures for exposing the MentorHub Developer Edition welcome portal on a remote host (such as the Spark host) via Tailscale Funnel over HTTPS.

## Architecture Overview

- **TLS Termination:** Tailscale Funnel terminates HTTPS externally, automatically provisioning and renewing Let's Encrypt certificates for your `*.ts.net` endpoint.
- **Internal HTTP:** NGINX and Docker containers communicate internally over standard HTTP (port 8080 on the host). No custom TLS configuration or certificates are needed in the containers or NGINX.
- **Port Exposure:** Tailscale Funnel forwards public HTTPS traffic (`https://<node>.ts.net`) strictly to `127.0.0.1:8080` (the welcome server).
- **Direct Port Isolation:** Direct-port debugging tools (MailPit on 8025, Stripe mock on 12111, Cognito mock on 9229) and API explorer ports (8383, 8397, etc.) remain private to the host / tailnet and are not exposed over the public Funnel.

## Configuration & Launch

On the Spark host:

### 1. Configure HOST_NAME

The Developer Edition scripts read `~/.mentorhub/HOST_NAME` to determine `IDP_LOGIN_URI` for journey SPAs. Specify the full HTTPS scheme:

```bash
echo "https://spark-478a.tailb0d293.ts.net" > ~/.mentorhub/HOST_NAME
```

> **Note:** Alternatively, you can explicitly export `IDP_LOGIN_URI="https://spark-478a.tailb0d293.ts.net/login.html"` or save it to `~/.mentorhub/IDP_LOGIN_URI`. If `HOST_NAME` is unset, `mh-restart.sh` defaults directly to `https://spark-478a.tailb0d293.ts.net/login.html`.

### 2. Restart the Stack (`mh-restart.sh`)

The `mh-restart.sh` script is designed for automated / OpenClaw agent execution on the Spark server:

```bash
cd ~/source/mentor-forge/mentorhub
./DeveloperEdition/mh-restart.sh
```

This script:
- Refreshes the `mentorhub` repo
- Resolves `IDP_LOGIN_URI` from `~/.mentorhub/HOST_NAME` (or defaults to Spark HTTPS)
- Stops current containers
- Pulls published container images from `ghcr.io`
- Starts the entire Developer Edition stack with `docker compose up --detach`

### 3. Enable Tailscale Funnel

Expose port 8080 via background Funnel:

```bash
sudo tailscale funnel --bg http://127.0.0.1:8080
sudo tailscale funnel status
```

## Verification Instructions

From any terminal (internal or external):

```bash
# 1. Verify Welcome portal responds over HTTPS
curl -I https://spark-478a.tailb0d293.ts.net/

# 2. Verify Discovery journey route is accessible
curl -I https://spark-478a.tailb0d293.ts.net/discovery/

# 3. Verify Discovery runtime configuration contains the Funnel login URI
curl -s https://spark-478a.tailb0d293.ts.net/discovery/runtime-config.js
```

Expected output for `runtime-config.js`:
```javascript
window.__MENTORHUB_RUNTIME__ = {
  ...
  IDP_LOGIN_URI: 'https://spark-478a.tailb0d293.ts.net/login.html',
  ...
};
```
