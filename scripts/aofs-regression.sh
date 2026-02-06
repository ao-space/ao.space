#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$ROOT_DIR/deploy/server"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.yml"
ENV_EXAMPLE="$DEPLOY_DIR/.env.aofs.example"
ENV_FILE="${AOSPACE_ENV_FILE:-$DEPLOY_DIR/.env.aofs}"

load_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo "created $ENV_FILE from template"
    echo "update passwords/ports in $ENV_FILE before production use"
  fi

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a

  if [[ "${AOSPACE_DATA_DIR:-}" = /* ]]; then
    DATA_DIR="$AOSPACE_DATA_DIR"
  else
    DATA_DIR="$DEPLOY_DIR/${AOSPACE_DATA_DIR:-./data-aofs}"
  fi

  FILEAPI_PORT="${FILEAPI_PORT:-2001}"
  AGENT_PORT="${AGENT_PORT:-5678}"
  GATEWAY_PORT="${GATEWAY_PORT:-8080}"
}

prepare_layout() {
  load_env

  mkdir -p \
    "$DATA_DIR/etc/ao-space/meta/shared" \
    "$DATA_DIR/data/files" \
    "$DATA_DIR/opt/eulixspace/image" \
    "$DATA_DIR/opt/eulixspace/data"

  cat > "$DATA_DIR/etc/ao-space/meta/shared/disk_info.json" <<JSON
{
  "diskInitialCode": 1,
  "diskInitialMessage": "ok",
  "diskInitialProgress": 100,
  "diskExpandCode": 2,
  "diskExpandMessage": "not_required",
  "diskExpandProgress": 0,
  "createdTime": "2026-01-01T00:00:00Z",
  "updatedTime": "2026-01-01T00:00:00Z",
  "raidType": 1,
  "raidDiskHwIds": ["mockdisk0"],
  "PrimaryStorageHwIds": ["mockdisk0"],
  "secondaryStorageHwIds": [],
  "diskMountInfos": [
    {
      "hwIds": ["mockdisk0"],
      "mountDevice": "/dev/mock0",
      "deviceUuid": "mock-uuid-0",
      "dviceSequenceNumber": 1,
      "mountPath": "/aospace/data/files",
      "dataFolderRoot": "default",
      "mapperName": "",
      "fSType": "ext4",
      "isPrimaryStorage": true
    }
  ],
  "fileStorageVolumePathPrefix": "bp_part_"
}
JSON

  mkdir -p "$DATA_DIR/data/files/bp_part_default"

  cat > "$DATA_DIR/etc/ao-space/meta/shared/shared_info.json" <<JSON
{
  "aoId": "ao-space-local",
  "boxName": "ao-space-local",
  "createdTime": "2026-01-01T00:00:00Z",
  "updatedTime": "2026-01-01T00:00:00Z"
}
JSON

  cat > "$DATA_DIR/etc/ao-space/internet_service_config.json" <<JSON
{
  "enableInternetAccess": false,
  "domain": "ao.space",
  "platformEnabled": false
}
JSON
}

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

ensure_gateway_db() {
  load_env
  local account_db="${POSTGRES_ACCOUNTDB:-account}"
  docker exec aospace-postgresql sh -lc \
    "psql -U ${POSTGRES_USER:-postgres} -tc \"SELECT 1 FROM pg_database WHERE datname='${account_db}'\" | grep -q 1 || psql -U ${POSTGRES_USER:-postgres} -c 'CREATE DATABASE ${account_db}'" >/dev/null
}

cmd_up() {
  prepare_layout
  compose up -d --build
  ensure_gateway_db
  compose up -d aospace-gateway >/dev/null
  echo "aofs stack started"
}

cmd_down() {
  load_env
  compose down
}

cmd_ps() {
  load_env
  compose ps
}

cmd_logs() {
  load_env
  compose logs -f --tail=200 aospace-fileapi aospace-agent aospace-gateway
}

cmd_smoke() {
  load_env
  local fileapi_url="http://127.0.0.1:2001/space/v1/api/status"
  local agent_url="http://127.0.0.1:5678/agent/status"
  local gateway_url="http://127.0.0.1:8080/space/v1/api/gateway/version/box/current"

  echo "checking container endpoint $fileapi_url"
  for i in {1..30}; do
    if docker exec aospace-fileapi wget -qO- "$fileapi_url" >/dev/null; then
      break
    fi
    sleep 2
  done
  if [[ "$i" -eq 30 ]]; then
    echo "fileapi smoke failed" >&2
    return 1
  fi

  echo "checking container endpoint $agent_url"
  for i in {1..30}; do
    if docker exec aospace-agent curl -fsS "$agent_url" >/dev/null; then
      break
    fi
    sleep 2
  done
  if [[ "$i" -eq 30 ]]; then
    echo "agent smoke failed" >&2
    return 1
  fi

  echo "checking container endpoint $gateway_url"
  for i in {1..30}; do
    if docker exec aospace-gateway curl -fsS -H 'Request-Id: smoke' "$gateway_url" | grep -q '"code":"GW-200"'; then
      echo "smoke passed"
      return 0
    fi
    sleep 2
  done
  echo "gateway smoke failed" >&2
  return 1
}

cmd_smoke_host() {
  load_env
  local fileapi_url="http://127.0.0.1:${FILEAPI_PORT}/space/v1/api/status"
  local agent_url="http://127.0.0.1:${AGENT_PORT}/agent/status"
  local gateway_url="http://127.0.0.1:${GATEWAY_PORT}/space/v1/api/gateway/version/box/current"

  echo "checking host endpoint $fileapi_url"
  for i in {1..30}; do
    if curl -fsS "$fileapi_url" >/dev/null; then
      break
    fi
    sleep 2
  done
  if [[ "$i" -eq 30 ]]; then
    echo "fileapi smoke failed" >&2
    return 1
  fi

  echo "checking host endpoint $agent_url"
  for i in {1..30}; do
    if curl -fsS "$agent_url" >/dev/null; then
      break
    fi
    sleep 2
  done
  if [[ "$i" -eq 30 ]]; then
    echo "agent smoke failed" >&2
    return 1
  fi

  echo "checking host endpoint $gateway_url"
  for i in {1..30}; do
    if curl -fsS -H 'Request-Id: smoke' "$gateway_url" | grep -q '"code":"GW-200"'; then
      echo "smoke passed"
      return 0
    fi
    sleep 2
  done
  echo "gateway smoke failed" >&2
  return 1
}

cmd_smoke_web() {
  load_env
  "$ROOT_DIR/scripts/web-smoke.sh"
}

cmd_config() {
  load_env
  compose config >/dev/null
  echo "compose config valid"
}

usage() {
  cat <<USAGE
Usage: $(basename "$0") <command>

Commands:
  up       prepare directories and start postgres+redis+aofs+agent+gateway
  down     stop and remove containers
  ps       show container status
  logs     tail core service logs
  smoke    run container-internal HTTP health smoke test (aofs+agent+gateway)
  smoke-host run host-mapped HTTP health smoke test (aofs+agent+gateway)
  smoke-web run web gateway/proxy smoke test via aospace-web container
  config   validate docker compose config
USAGE
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    up) cmd_up ;;
    down) cmd_down ;;
    ps) cmd_ps ;;
    logs) cmd_logs ;;
    smoke) cmd_smoke ;;
    smoke-host) cmd_smoke_host ;;
    smoke-web) cmd_smoke_web ;;
    config) cmd_config ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
