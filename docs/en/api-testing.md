# API Testing and Endpoint Inventory (Minimal Deployment)

## Scope
This plan targets the smallest runnable setup: `space-aofs + space-agent + space-gateway`, with no platform dependency.
The endpoint inventory is extracted from router code (not legacy docs).

## Server API Inventory
### space-aofs (`/space/v1/api`)
1. File: `GET /file/info` `GET /file/list` `POST /file/rename` `POST /file/copy` `POST /file/move` `POST /file/delete` `GET /file/download` `GET /file/search` `GET /file/thumb` `GET /file/compressed` `POST /file/vod/symlink`
2. Folder: `POST /folder/create` `GET /folder/info`
3. User: `POST /user/init` `POST /user/delete` `GET /user/storage`
4. Recycle: `GET /recycled/list` `POST /recycled/restore` `GET|POST /recycled/clear`
5. Multipart: `POST /multipart/create` `POST /multipart/upload` `GET /multipart/list` `POST /multipart/complete` `POST /multipart/delete`
6. Other: `GET /sync/synced` `GET /async/task` `GET /status` `GET /inner/file/info` `POST /inner/file/infos`

### space-agent
1. External: `/agent/v1/api/*` (pair/bind/network/did/switch/passthrough) + `GET /agent/status` `GET /agent/info`
2. Internal: `/agent/v1/api/device/*` `/upgrade/*` `/network/*` `/system/*` `/cert/get` `/bind/internet/service/config` `/did/*`

## Android Gap Analysis
`client/client-android/app/src/main/java/xyz/eulix/space/util/ConstantField.java` references many APIs that need gateway/platform services.

Directly covered in minimal mode: file/folder/recycled/multipart/status, core agent baseline flow, and gateway baseline entrypoints.

Deferred or unsupported now: full platform-dependent features (`member/personal/security/notification` complete flows), and agent constants like `reset/authinfo/disk/*/upgrade/start-*` that do not map to active routes.

## Implemented Test Code
1. Route contract tests (detect accidental route drops)
- `server/space-aofs/routers/routers/routes_contract_test.go`
- `server/space-agent/biz/web/routers/routes_contract_test.go`
2. Runtime smoke checks: `scripts/api-smoke.sh`
3. Regression assertions with business code checks: `scripts/api-regression.sh`
4. Write-path end-to-end: `scripts/api-e2e-write.sh`
5. Multipart end-to-end: `scripts/api-e2e-multipart.sh`
6. Full regression entrypoint: `scripts/api-full-regression.sh`
7. Error code contract: `docs/en/api-error-contract.md`

## Key Regression Assertions
1. `GET /space/v1/api/status`: must return `code=200` without `userId` (health check must be no-arg).
2. `GET /space/v1/api/file/list`: missing `userId` must return `code=1001` instead of dropping the connection.
3. `GET /space/v1/api/async/task?userId=1`: missing `taskId` currently returns `code=1062` (task not found).
4. Agent baseline availability: `/agent/status` and `/agent/info` return `code=AG-200`.
5. Gateway baseline availability: `/space/v1/api/gateway/version/box/current` returns `GW-400` without `Request-Id`, and `GW-200` with `Request-Id`.

## Run Commands
1. `cd server/space-aofs && go test ./routers/routers -run TestInitRoute_RegistersExpectedAPIs`
2. `cd server/space-agent && go test ./biz/web/routers -run Test.*Router_RegistersExpectedAPIs`
3. After services start: `AOFS_BASE=http://127.0.0.1:8090 AGENT_BASE=http://127.0.0.1:5680 ./scripts/api-smoke.sh`
4. Full regression: `AOFS_BASE=http://127.0.0.1:8090 AGENT_BASE=http://127.0.0.1:5680 ./scripts/api-regression.sh`
5. Write-flow regression: `AOFS_BASE=http://127.0.0.1:8090 ./scripts/api-e2e-write.sh`
6. Multipart regression: `AOFS_BASE=http://127.0.0.1:8090 ./scripts/api-e2e-multipart.sh`
7. One-shot full suite: `AOFS_BASE=http://127.0.0.1:8090 AGENT_BASE=http://127.0.0.1:5680 ./scripts/api-full-regression.sh`

## iOS Regression (2026-02-07)
1. Command: `cd client/client-ios && xcodebuild -workspace EulixSpace.xcworkspace -scheme EulixSpace -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:EulixSpaceTests test`
2. Result: `12 passed, 0 failed`
3. Focus areas:
- stale box request rejection (prevent fallback to old box host)
- LAN host override only for the same `boxUUID`
- LAN cert response parsing compatibility (string / dict / nested dict)
