#!/usr/bin/env bash
set -euo pipefail

AOFS_BASE="${AOFS_BASE:-http://127.0.0.1:2001}"
AGENT_BASE="${AGENT_BASE:-}"
GATEWAY_BASE="${GATEWAY_BASE:-}"
USER_ID="${USER_ID:-1}"

echo "[INFO] full regression start"

AOFS_BASE="$AOFS_BASE" AGENT_BASE="$AGENT_BASE" GATEWAY_BASE="$GATEWAY_BASE" ./scripts/api-smoke.sh
AOFS_BASE="$AOFS_BASE" AGENT_BASE="$AGENT_BASE" GATEWAY_BASE="$GATEWAY_BASE" ./scripts/api-regression.sh
AOFS_BASE="$AOFS_BASE" USER_ID="$USER_ID" ./scripts/api-e2e-write.sh
AOFS_BASE="$AOFS_BASE" USER_ID="$USER_ID" ./scripts/api-e2e-multipart.sh

echo "[DONE] full regression passed"
