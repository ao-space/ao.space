#!/usr/bin/env bash
set -euo pipefail

AOFS_BASE="${AOFS_BASE:-http://127.0.0.1:8090}"
AGENT_BASE="${AGENT_BASE:-}"
GATEWAY_BASE="${GATEWAY_BASE:-}"

check_not_404_405() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local code
  if [[ -n "$body" ]]; then
    code=$(curl -sS -o /dev/null -w '%{http_code}' -X "$method" -H 'Content-Type: application/json' "$url" -d "$body")
  else
    code=$(curl -sS -o /dev/null -w '%{http_code}' -X "$method" "$url")
  fi

  if [[ "$code" == "404" || "$code" == "405" ]]; then
    echo "[FAIL] $method $url -> $code"
    return 1
  fi
  echo "[PASS] $method $url -> $code"
}

echo "[INFO] AOFS smoke: $AOFS_BASE"
curl -fsS "$AOFS_BASE/space/v1/api/status" >/dev/null
echo "[PASS] GET $AOFS_BASE/space/v1/api/status"

check_not_404_405 GET "$AOFS_BASE/space/v1/api/file/list?userId=1"
check_not_404_405 GET "$AOFS_BASE/space/v1/api/recycled/list?userId=1"
check_not_404_405 POST "$AOFS_BASE/space/v1/api/multipart/create?userId=1" '{"name":"smoke.bin","size":1}'

if [[ -n "$AGENT_BASE" ]]; then
  echo "[INFO] AGENT smoke: $AGENT_BASE"
  check_not_404_405 GET "$AGENT_BASE/agent/status"
  check_not_404_405 GET "$AGENT_BASE/agent/v1/api/pair/init"
  check_not_404_405 GET "$AGENT_BASE/agent/v1/api/space/ready/check"
fi

if [[ -n "$GATEWAY_BASE" ]]; then
  echo "[INFO] GATEWAY smoke: $GATEWAY_BASE"
  check_not_404_405 GET "$GATEWAY_BASE/space/v1/api/gateway/version/box/current"
  code=$(curl -sS -o /dev/null -w '%{http_code}' -H 'Request-Id: smoke' "$GATEWAY_BASE/space/v1/api/gateway/version/box/current")
  if [[ "$code" != "200" ]]; then
    echo "[FAIL] GET $GATEWAY_BASE/space/v1/api/gateway/version/box/current with Request-Id -> $code"
    exit 1
  fi
  echo "[PASS] GET $GATEWAY_BASE/space/v1/api/gateway/version/box/current with Request-Id -> 200"
fi

echo "[DONE] api smoke completed"
