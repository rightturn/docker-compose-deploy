# docker-compose-deploy

A small, complete example of deploying a containerised app with **Docker Compose**, **nginx**,
**health checks**, **automatic rollback** and **GitHub Actions**.

![CI](https://github.com/rightturn/docker-compose-deploy/actions/workflows/ci.yml/badge.svg)

The app itself is deliberately tiny (a Node.js JSON service). The point is the delivery pipeline around it.

## What it shows
- **Multi-service Compose stack:** app + nginx reverse proxy, started in the right order
  (`depends_on` with a health condition).
- **Container hardening:** non-root user, read-only filesystem, all Linux capabilities dropped,
  `no-new-privileges`, version-tagged base images.
- **Health checks** at the image level (`HEALTHCHECK`) and at the edge (`/health` through nginx).
- **Safe deploys:** `scripts/deploy.sh` fetches the target commit, rebuilds, waits for `/health`,
  and **rolls back to the previous commit automatically** if the new version is not healthy.
- **CI:** unit tests, a build, and a smoke test through nginx on every push and pull request.
- **Manual deploy workflow** over SSH with host-key pinning (no `StrictHostKeyChecking=no`).

## Endpoints
| Path | Response |
|---|---|
| `/` | greeting and the running version (the git commit that was deployed) |
| `/health` | `{"status":"ok", ...}` used by Docker and by the deploy script |

## Run it locally
```bash
docker compose up --build
curl localhost:8080/health          # change the port with HTTP_PORT=9000
docker compose down
```
Tests: `cd app && npm test` (Node 22, no dependencies).

## Deploy to a server
On the server (Docker + Compose + git + curl installed):
```bash
git clone https://github.com/rightturn/docker-compose-deploy.git /opt/app
cd /opt/app && ./scripts/deploy.sh
```
Every later `./scripts/deploy.sh` deploys the newest commit of `main`. Output looks like:
```
[deploy] current daaeeda -> target 32d9b28
[deploy] new version did NOT become healthy; rolling back to daaeeda
[deploy] rollback succeeded; still serving daaeeda
```
(That is a real run of a deliberately broken release, tested against a throw-away "server".)

### Deploy from GitHub Actions
Add these repository secrets (Settings, Secrets and variables, Actions), then run
**Actions, Deploy, Run workflow**:

| Secret | Value |
|---|---|
| `SSH_HOST` | server address |
| `SSH_USER` | deploy user |
| `SSH_KEY` | private key for that user (use a dedicated deploy key) |
| `SSH_KNOWN_HOSTS` | output of `ssh-keyscan -H your.server` (verify the fingerprint yourself) |
| `DEPLOY_PATH` | path of the clone, e.g. `/opt/app` |

## Layout
```
app/                 the service and its tests
nginx/default.conf   reverse proxy
Dockerfile           small, non-root image with a health check
docker-compose.yml   app + web
scripts/deploy.sh    deploy with health check and rollback
.github/workflows/   ci.yml (tests + smoke test), deploy.yml (manual SSH deploy)
```

## License
MIT
