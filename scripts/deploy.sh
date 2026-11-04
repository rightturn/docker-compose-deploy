#!/usr/bin/env bash
# Deploy the latest commit of a branch with Docker Compose.
# If the new version does not become healthy, roll back to the previous commit.
#
# Run on the server, inside a git clone of the repository:
#   ./scripts/deploy.sh
#
# Optional environment variables:
#   DEPLOY_BRANCH   branch to deploy            (default: main)
#   HTTP_PORT       port nginx listens on       (default: 8080)
#   HEALTH_URL      URL that must return 200    (default: http://localhost:$HTTP_PORT/health)
#   HEALTH_TIMEOUT  seconds to wait for health  (default: 60)
set -euo pipefail
cd "$(dirname "$0")/.."

BRANCH="${DEPLOY_BRANCH:-main}"
HTTP_PORT="${HTTP_PORT:-8080}"
HEALTH_URL="${HEALTH_URL:-http://localhost:${HTTP_PORT}/health}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-60}"
export HTTP_PORT

log() { printf '[deploy] %s\n' "$*"; }

wait_healthy() {
  local waited=0
  until curl -fsS --max-time 3 "$HEALTH_URL" >/dev/null 2>&1; do
    waited=$((waited + 2))
    if [ "$waited" -ge "$HEALTH_TIMEOUT" ]; then return 1; fi
    sleep 2
  done
}

release() {
  # $1 = full commit sha to run
  git reset --hard --quiet "$1"
  APP_VERSION="$(git rev-parse --short HEAD)" docker compose up -d --build --remove-orphans
}

PREVIOUS="$(git rev-parse HEAD)"
git fetch --quiet origin "$BRANCH"
TARGET="$(git rev-parse "origin/${BRANCH}")"

log "current ${PREVIOUS:0:7} -> target ${TARGET:0:7}"
if release "$TARGET" && wait_healthy; then
  log "healthy at $HEALTH_URL"
  docker image prune -f >/dev/null 2>&1 || true
  exit 0
fi

log "new version did NOT become healthy; rolling back to ${PREVIOUS:0:7}"
docker compose logs --tail=30 app || true
release "$PREVIOUS"
if wait_healthy; then
  log "rollback succeeded; still serving ${PREVIOUS:0:7}"
else
  log "rollback did not become healthy either: manual action needed"
fi
exit 1
