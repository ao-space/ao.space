# API Error Code Contract (Minimal Deployment)

This document defines stable code-level contracts used by regression tests for the minimal deployment (`space-aofs + space-agent + space-gateway`).

## space-aofs
1. `GET /space/v1/api/status`
- Expected: `code=200`
- Notes: health check must work without `userId`.

2. `GET /space/v1/api/file/list` (missing `userId`)
- Expected: `code=1001`
- Notes: parameter error must be returned as business response; no connection drop.

3. `GET /space/v1/api/async/task?userId=1` (missing `taskId`)
- Expected: `code=1062`
- Notes: current implementation treats this as task-not-found.

4. `POST /space/v1/api/multipart/upload` (duplicate range)
- Expected: `code=1037`
- Notes: uploaded range already exists.

## space-agent
1. `GET /agent/status`
2. `GET /agent/v1/api/pair/init`
3. `GET /agent/v1/api/space/ready/check`
- Expected: HTTP 200 and `code=AG-200`
- Notes: `space-agent` business code is a string, not an integer.

## space-gateway
1. `GET /space/v1/api/gateway/version/box/current` (without `Request-Id`)
- Expected: HTTP `400` and `code=GW-400`

2. `GET /space/v1/api/gateway/version/box/current` (with `Request-Id`)
- Expected: HTTP `200` and `code=GW-200`

## Contract Execution Entrypoints
1. Baseline assertions: `scripts/api-regression.sh`
2. Write-flow assertions: `scripts/api-e2e-write.sh`
3. Multipart-flow assertions: `scripts/api-e2e-multipart.sh`
4. Full regression: `scripts/api-full-regression.sh`
