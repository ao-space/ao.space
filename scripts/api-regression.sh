#!/usr/bin/env bash
set -euo pipefail

AOFS_BASE="${AOFS_BASE:-http://127.0.0.1:2001}"
AGENT_BASE="${AGENT_BASE:-}"
GATEWAY_BASE="${GATEWAY_BASE:-}"

fail=0

call_case() {
  local name="$1"
  local method="$2"
  local url="$3"
  local expect_http="$4"
  local expect_code="$5"
  local body="${6:-}"
  local request_id="${7:-}"

  local tmp
  tmp=$(mktemp)
  local http
  if [[ -n "$body" ]]; then
    if [[ -n "$request_id" ]]; then
      http=$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" -H 'Content-Type: application/json' -H "Request-Id: $request_id" "$url" -d "$body" || true)
    else
      http=$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" -H 'Content-Type: application/json' "$url" -d "$body" || true)
    fi
  else
    if [[ -n "$request_id" ]]; then
      http=$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" -H "Request-Id: $request_id" "$url" || true)
    else
      http=$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" "$url" || true)
    fi
  fi

  local biz
  biz=$(sed -n 's/.*"code"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$tmp" | head -n1)
  if [[ -z "$biz" ]]; then
    biz=$(sed -n 's/.*"code"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$tmp" | head -n1)
  fi

  if [[ "$http" == "$expect_http" && "$biz" == "$expect_code" ]]; then
    echo "[PASS] $name -> http=$http code=$biz"
  else
    echo "[FAIL] $name -> http=$http code=${biz:-<none>} expected_http=$expect_http expected_code=$expect_code"
    echo "       url=$url"
    echo "       resp=$(tr -d '\n' < "$tmp" | cut -c1-220)"
    fail=1
  fi

  rm -f "$tmp"
}

echo "[INFO] AOFS regression base=$AOFS_BASE"
call_case "aofs_status_no_userid" GET "$AOFS_BASE/space/v1/api/status" 200 200
call_case "aofs_file_list_ok" GET "$AOFS_BASE/space/v1/api/file/list?userId=1" 200 200
call_case "aofs_file_list_missing_userid" GET "$AOFS_BASE/space/v1/api/file/list" 200 1001
call_case "aofs_recycled_list_ok" GET "$AOFS_BASE/space/v1/api/recycled/list?userId=1" 200 200
call_case "aofs_async_task_missing_taskid" GET "$AOFS_BASE/space/v1/api/async/task?userId=1" 200 1062

if [[ -n "$AGENT_BASE" ]]; then
  echo "[INFO] AGENT regression base=$AGENT_BASE"
  call_case "agent_status" GET "$AGENT_BASE/agent/status" 200 AG-200
  call_case "agent_info" GET "$AGENT_BASE/agent/info" 200 AG-200
else
  echo "[INFO] AGENT regression skipped (AGENT_BASE is empty)"
fi

if [[ -n "$GATEWAY_BASE" ]]; then
  echo "[INFO] GATEWAY regression base=$GATEWAY_BASE"
  call_case "gateway_version_current_without_requestid" GET "$GATEWAY_BASE/space/v1/api/gateway/version/box/current" 400 GW-400
  call_case "gateway_version_current_with_requestid" GET "$GATEWAY_BASE/space/v1/api/gateway/version/box/current" 200 GW-200 "" "smoke"
else
  echo "[INFO] GATEWAY regression skipped (GATEWAY_BASE is empty)"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "[DONE] api regression failed"
  exit 1
fi

echo "[DONE] api regression passed"
