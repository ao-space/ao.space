#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$ROOT_DIR/deploy/server"
ENV_FILE="${AOSPACE_ENV_FILE:-$DEPLOY_DIR/.env.aofs}"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.yml"
WEB_CONTAINER="${AOSPACE_WEB_CONTAINER:-aospace-web}"
PROBE_CONTAINER="${AOSPACE_WEB_PROBE_CONTAINER:-aospace-gateway}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

require_container() {
  local name="$1"
  if ! docker ps --format '{{.Names}}' | grep -qx "$name"; then
    echo "container not running: $name" >&2
    exit 1
  fi
}

probe_get() {
  local path="$1"
  local request_id="${2:-web-smoke}"
  docker exec "$PROBE_CONTAINER" sh -lc \
    "curl -fsS -H 'Request-Id: ${request_id}' 'http://${WEB_CONTAINER}${path}'"
}

assert_web_json_contains() {
  local path="$1"
  local expected="$2"
  local request_id="${3:-web-smoke}"

  local body
  body="$(probe_get "$path" "$request_id")"

  if ! grep -q "$expected" <<<"$body"; then
    echo "web smoke failed on ${path}" >&2
    echo "expected pattern: $expected" >&2
    echo "actual body: $body" >&2
    exit 1
  fi
  echo "[PASS] ${path}"
}

assert_web_http_200() {
  local path="$1"
  if ! docker exec "$PROBE_CONTAINER" sh -lc "curl -fsS 'http://${WEB_CONTAINER}${path}' >/dev/null"; then
    echo "web smoke failed on ${path}, status!=200" >&2
    exit 1
  fi
  echo "[PASS] ${path} -> 200"
}

main() {
  require_container "$WEB_CONTAINER"
  require_container "$PROBE_CONTAINER"

  echo "[CHECK] web landing"
  assert_web_http_200 "/"

  echo "[CHECK] web status"
  assert_web_json_contains "/space/status" '"status":"ok"'

  echo "[CHECK] gateway version current via web"
  assert_web_json_contains "/space/v1/api/gateway/version/box/current" '"code":"GW-200"' "web-smoke-version-current"

  echo "web smoke passed"
}

main "$@"
